import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
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

      await expectLater(
        ownerItems.completeDiscovery(
          DiscoverySubmission(
            submissionId: '70000000-0000-4000-8000-000000000007',
            kind: LearningItemKind.expression,
            content: 'Discovery validation fixture',
            meaning: 'a rejected oversized authored field',
            source: 's' * 1001,
            allowExistingSurface: false,
          ),
        ),
        throwsA(
          isA<DiscoveryFailure>()
              .having(
                (failure) => failure.code,
                'code',
                DiscoveryFailureCode.discoveryValidationRejected,
              )
              .having(
                (failure) => failure.metadata.field,
                'field',
                DiscoveryFailureField.source,
              ),
        ),
      );

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

      for (final fixture in [
        (
          submissionId: '50000000-0000-4000-8000-000000000005',
          content: 'Discovery replay fixture false',
          allowExistingSurface: false,
        ),
        (
          submissionId: '60000000-0000-4000-8000-000000000006',
          content: 'Discovery replay fixture true',
          allowExistingSurface: true,
        ),
      ]) {
        final submission = DiscoverySubmission(
          submissionId: fixture.submissionId,
          kind: LearningItemKind.expression,
          content: fixture.content,
          meaning: 'an idempotent concurrent submission',
          allowExistingSurface: fixture.allowExistingSurface,
        );
        final replayRelease = Completer<void>();
        final ownerResult = _completeAfter(
          replayRelease.future,
          ownerItems,
          submission,
        );
        final restoredResult = _completeAfter(
          replayRelease.future,
          restoredItems,
          submission,
        );
        replayRelease.complete();
        final replaySettled = await Future.wait([ownerResult, restoredResult]);

        expect(replaySettled.every((result) => result.error == null), isTrue);
        expect(
          replaySettled.map((result) => result.value.runtimeType).toSet(),
          {DiscoveryCreated, DiscoveryReplayed},
        );
        expect(
          replaySettled.map((result) => result.value!.item.id).toSet(),
          hasLength(1),
        );
        expect(
          await ownerItems.findActiveBySurfaceForm(fixture.content),
          hasLength(1),
        );
        await ownerClient
            .from('learning_items')
            .delete()
            .eq('id', replaySettled.first.value!.item.id);
      }

      const conflictingId = '80000000-0000-4000-8000-000000000008';
      const firstPayload = DiscoverySubmission(
        submissionId: conflictingId,
        kind: LearningItemKind.expression,
        content: 'Discovery submission lock fixture A',
        meaning: 'the first payload',
        allowExistingSurface: true,
      );
      const secondPayload = DiscoverySubmission(
        submissionId: conflictingId,
        kind: LearningItemKind.expression,
        content: 'Discovery submission lock fixture B',
        meaning: 'the second payload',
        allowExistingSurface: true,
      );
      final conflictRelease = Completer<void>();
      final firstConflict = _completeAfter(
        conflictRelease.future,
        ownerItems,
        firstPayload,
      );
      final secondConflict = _completeAfter(
        conflictRelease.future,
        restoredItems,
        secondPayload,
      );
      conflictRelease.complete();
      final conflictSettled = await Future.wait([
        firstConflict,
        secondConflict,
      ]);
      expect(
        conflictSettled.where((result) => result.value is DiscoveryCreated),
        hasLength(1),
      );
      expect(
        conflictSettled
            .map((result) => result.error)
            .whereType<DiscoveryFailure>()
            .single
            .code,
        DiscoveryFailureCode.discoverySubmissionConflict,
      );
      final conflictItem = conflictSettled
          .map((result) => result.value)
          .whereType<DiscoveryCreated>()
          .single
          .item;
      await ownerClient
          .from('learning_items')
          .delete()
          .eq('id', conflictItem.id);

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
