import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_learning_item_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_review_repository.dart';

typedef _SettledDiscovery = ({DiscoveryCompletion? value, Object? error});

void main() {
  final localUrl = Platform.environment['LOCAL_SUPABASE_URL'];
  final localKey = Platform.environment['LOCAL_SUPABASE_PUBLISHABLE_KEY'];
  final canRun = localUrl != null && localKey != null;

  test(
    'same-owner clients serialize Discovery, replay, ownership, and review facts',
    () async {
      final ownerClient = SupabaseClient(localUrl!, localKey!);
      final restoredClient = SupabaseClient(localUrl, localKey);
      final otherClient = SupabaseClient(localUrl, localKey);
      final ownerItems = SupabaseLearningItemRepository(ownerClient);
      final restoredItems = SupabaseLearningItemRepository(restoredClient);
      final otherItems = SupabaseLearningItemRepository(otherClient);
      final ownerReviews = SupabaseReviewRepository(ownerClient);
      addTearDown(() async {
        await Future.wait([
          ownerClient.dispose(),
          restoredClient.dispose(),
          otherClient.dispose(),
        ]);
      });

      final ownerAuth = await ownerClient.auth.signInAnonymously();
      final ownerSession = ownerAuth.session!;
      await restoredClient.auth.setSession(
        ownerSession.refreshToken!,
        accessToken: ownerSession.accessToken,
      );
      await restoredClient.auth.refreshSession();
      await otherClient.auth.signInAnonymously();

      const firstSubmission = DiscoverySubmission(
        submissionId: '10000000-0000-4000-8000-000000000001',
        kind: LearningItemKind.vocabulary,
        content: 'Discovery concurrency fixture',
        partOfSpeech: 'noun',
        meaning: 'the first intended sense',
        firstProduction: 'I used the fixture in a sentence.',
        allowExistingSurface: false,
      );
      const competingSubmission = DiscoverySubmission(
        submissionId: '20000000-0000-4000-8000-000000000002',
        kind: LearningItemKind.vocabulary,
        content: '  discovery   concurrency fixture  ',
        partOfSpeech: 'verb',
        meaning: 'a competing intended sense',
        firstProduction: 'The fixture competed safely.',
        allowExistingSurface: false,
      );
      final release = Completer<void>();
      final first = _completeAfter(release.future, ownerItems, firstSubmission);
      final second = _completeAfter(
        release.future,
        restoredItems,
        competingSubmission,
      );
      release.complete();
      final settled = await Future.wait([first, second]);
      expect(settled.every((result) => result.error == null), isTrue);
      expect(settled.map((result) => result.value.runtimeType).toSet(), {
        DiscoveryCreated,
        DiscoveryExistingSurface,
      });

      final original = settled
          .map((result) => result.value)
          .whereType<DiscoveryCreated>()
          .single
          .item;
      expect(original.lastReviewedAt, isNull);
      expect(original.reviewCount, 0);
      expect(await ownerItems.listDue(at: DateTime.now().toUtc()), isEmpty);
      expect(
        await restoredItems.findActiveBySurfaceForm(
          'DISCOVERY concurrency fixture',
        ),
        hasLength(1),
      );
      expect(
        await otherItems.findActiveBySurfaceForm(original.content),
        isEmpty,
      );

      const additionalSubmission = DiscoverySubmission(
        submissionId: '30000000-0000-4000-8000-000000000003',
        kind: LearningItemKind.vocabulary,
        content: 'discovery concurrency fixture',
        partOfSpeech: 'adjective',
        meaning: 'an explicitly additional sense',
        allowExistingSurface: true,
      );
      final additional = await ownerItems.completeDiscovery(
        additionalSubmission,
      );
      expect(additional, isA<DiscoveryCreated>());
      expect(
        await ownerItems.findActiveBySurfaceForm(original.content),
        hasLength(2),
      );

      final winningSubmission = settled.first.value is DiscoveryCreated
          ? firstSubmission
          : competingSubmission;
      final replay = await restoredItems.completeDiscovery(winningSubmission);
      expect(replay, isA<DiscoveryReplayed>());
      expect((replay as DiscoveryReplayed).item.id, original.id);
      expect(replay.item.lastReviewedAt, isNull);

      final reviewed = await ownerReviews.completeReview(
        item: original,
        submissionId: '40000000-0000-4000-8000-000000000004',
        responseText: 'A rated production.',
        rating: ReviewRating.good,
      );
      expect(reviewed.lastReviewedAt, isNotNull);
      expect(reviewed.reviewCount, 1);
      final replayAfterReview = await restoredItems.completeDiscovery(
        winningSubmission,
      );
      expect(
        (replayAfterReview as DiscoveryReplayed).item.lastReviewedAt,
        reviewed.lastReviewedAt,
      );
      expect(replayAfterReview.item.reviewCount, 1);

      expect(
        await otherClient.from('learning_items').select('id').inFilter('id', [
          original.id,
          (additional as DiscoveryCreated).item.id,
        ]),
        isEmpty,
      );
      await ownerClient.from('learning_items').delete().inFilter('id', [
        original.id,
        additional.item.id,
      ]);
    },
    skip: canRun
        ? false
        : 'Requires LOCAL_SUPABASE_URL and LOCAL_SUPABASE_PUBLISHABLE_KEY.',
  );
}

Future<_SettledDiscovery> _completeAfter(
  Future<void> release,
  SupabaseLearningItemRepository repository,
  DiscoverySubmission submission,
) async {
  await release;
  try {
    return (value: await repository.completeDiscovery(submission), error: null);
  } on Object catch (error) {
    return (value: null, error: error);
  }
}
