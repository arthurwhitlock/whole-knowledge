import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/learning/capture_learning_item.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_learning_item_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_review_repository.dart';

typedef _SettledReview = ({LearningItem? value, Object? error});

void main() {
  final localUrl = Platform.environment['LOCAL_SUPABASE_URL'];
  final localKey = Platform.environment['LOCAL_SUPABASE_PUBLISHABLE_KEY'];
  final canRun = localUrl != null && localKey != null;

  test(
    'anonymous sessions enforce ownership and serialize competing reviews',
    () async {
      final url = localUrl!;
      final key = localKey!;
      final ownerClient = SupabaseClient(url, key);
      final restoredOwnerClient = SupabaseClient(url, key);
      final otherClient = SupabaseClient(url, key);
      final ownerItems = SupabaseLearningItemRepository(ownerClient);
      final restoredOwnerItems = SupabaseLearningItemRepository(
        restoredOwnerClient,
      );
      final otherItems = SupabaseLearningItemRepository(otherClient);
      final ownerReviews = SupabaseReviewRepository(ownerClient);
      final restoredOwnerReviews = SupabaseReviewRepository(
        restoredOwnerClient,
      );
      final otherReviews = SupabaseReviewRepository(otherClient);
      addTearDown(() async {
        await Future.wait([
          ownerClient.dispose(),
          restoredOwnerClient.dispose(),
          otherClient.dispose(),
        ]);
      });

      final ownerAuth = await ownerClient.auth.signInAnonymously();
      final ownerSession = ownerAuth.session;
      expect(ownerSession, isNotNull);

      final restoredAuth = await restoredOwnerClient.auth.setSession(
        ownerSession!.refreshToken!,
        accessToken: ownerSession.accessToken,
      );
      expect(restoredAuth.user?.id, ownerSession.user.id);

      final refreshedAuth = await restoredOwnerClient.auth.refreshSession();
      expect(refreshedAuth.user?.id, ownerSession.user.id);

      final otherAuth = await otherClient.auth.signInAnonymously();
      expect(otherAuth.user, isNotNull);
      expect(otherAuth.user!.id, isNot(ownerSession.user.id));

      final item = await ownerItems.create(
        const CaptureLearningItem(
          kind: LearningItemKind.expression,
          content: 'local concurrency fixture',
        ),
      );
      final itemId = item.id;

      final ownerDue = await ownerItems.listDue(at: DateTime.now().toUtc());
      final restoredDue = await restoredOwnerItems.listDue(
        at: DateTime.now().toUtc(),
      );
      expect(ownerDue, hasLength(1));
      expect(restoredDue, hasLength(1));
      expect(ownerDue.single.id, itemId);
      expect(restoredDue.single.id, itemId);
      expect(ownerDue.single.reviewCount, 0);
      expect(restoredDue.single.reviewCount, 0);
      expect(await otherItems.listDue(at: DateTime.now().toUtc()), isEmpty);

      final release = Completer<void>();
      final first = _completeAfter(
        release.future,
        ownerReviews,
        item: ownerDue.single,
        submissionId: 'c0000000-0000-4000-8000-00000000000c',
        responseText: 'First competing response',
      );
      final second = _completeAfter(
        release.future,
        restoredOwnerReviews,
        item: restoredDue.single,
        submissionId: 'd0000000-0000-4000-8000-00000000000d',
        responseText: 'Second competing response',
      );
      release.complete();

      final results = await Future.wait([first, second]);
      final successes = results
          .where((result) => result.value != null)
          .toList();
      final failures = results.where((result) => result.error != null).toList();
      expect(successes, hasLength(1));
      expect(failures, hasLength(1));
      expect(failures.single.error, isA<PostgrestException>());
      expect(
        (failures.single.error! as PostgrestException).message,
        contains('Learning item changed or is unavailable'),
      );

      final storedItem = await ownerClient
          .from('learning_items')
          .select()
          .eq('id', itemId)
          .single();
      expect(storedItem['review_count'], 1);
      expect(storedItem['production_count'], 1);
      final nextReviewAt = DateTime.parse(
        storedItem['next_review_at']! as String,
      );
      final updatedAt = DateTime.parse(storedItem['updated_at']! as String);
      expect(nextReviewAt.difference(updatedAt), const Duration(days: 3));
      expect(await ownerItems.listDue(at: DateTime.now().toUtc()), isEmpty);
      final ownerLibrary = await ownerItems.listAll();
      expect(ownerLibrary, hasLength(1));
      expect(ownerLibrary.single.reviewCount, 1);

      final attempts = await ownerClient
          .from('review_attempts')
          .select()
          .eq('learning_item_id', itemId);
      expect(attempts, hasLength(2));
      expect(
        attempts.map((row) => row['review_submission_id']).toSet(),
        hasLength(1),
      );
      expect(attempts.map((row) => row['attempt_type']).toSet(), {
        'retrieval',
        'production',
      });

      final winningSubmissionId =
          attempts.first['review_submission_id']! as String;
      final winningResponse = attempts.singleWhere(
        (row) => row['attempt_type'] == 'production',
      );
      final replayed = await restoredOwnerReviews.completeReview(
        item: restoredDue.single,
        submissionId: winningSubmissionId,
        responseText: winningResponse['response_text']! as String,
        rating: ReviewRating.good,
      );
      expect(replayed.reviewCount, 1);
      expect(replayed.productionCount, 1);
      expect(
        await ownerClient
            .from('review_attempts')
            .select('id')
            .eq('learning_item_id', itemId),
        hasLength(2),
      );

      expect(
        () => otherReviews.completeReview(
          item: ownerLibrary.single,
          submissionId: 'e0000000-0000-4000-8000-00000000000e',
          responseText: 'Cross-owner response',
          rating: ReviewRating.good,
        ),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        () => otherClient
            .from('learning_items')
            .update({'content': 'cross-owner mutation'})
            .eq('id', itemId),
        throwsA(isA<PostgrestException>()),
      );
      expect(
        await otherClient.from('learning_items').select('id').eq('id', itemId),
        isEmpty,
      );
      expect(
        await otherClient
            .from('learning_items')
            .delete()
            .eq('id', itemId)
            .select(),
        isEmpty,
      );
      expect(
        await otherClient
            .from('review_attempts')
            .select('id')
            .eq('learning_item_id', itemId),
        isEmpty,
      );

      await ownerClient.from('learning_items').delete().eq('id', itemId);
    },
    skip: canRun
        ? false
        : 'Requires LOCAL_SUPABASE_URL and LOCAL_SUPABASE_PUBLISHABLE_KEY.',
  );
}

Future<_SettledReview> _completeAfter(
  Future<void> release,
  SupabaseReviewRepository reviews, {
  required LearningItem item,
  required String submissionId,
  required String responseText,
}) async {
  await release;
  try {
    return (
      value: await reviews.completeReview(
        item: item,
        submissionId: submissionId,
        responseText: responseText,
        rating: ReviewRating.good,
      ),
      error: null,
    );
  } on Object catch (error) {
    return (value: null, error: error);
  }
}
