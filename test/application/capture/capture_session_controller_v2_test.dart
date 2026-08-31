import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

import '../../support/fakes.dart';

void main() {
  test(
    'attempted checkpoint restores into same-payload reconciliation',
    () async {
      const submission = DiscoverySubmission(
        submissionId: 'submission-1',
        kind: LearningItemKind.expression,
        content: 'on the record',
        meaning: 'officially',
        allowExistingSurface: false,
      );
      final drafts = FakeCaptureDraftRepository()
        ..saved = const CaptureDraft(
          content: 'on the record',
          meaning: 'officially',
          submissionCheckpoint: DiscoverySubmissionCheckpoint(
            status: DiscoverySubmissionCheckpointStatus.attempted,
            submission: submission,
          ),
        );
      final controller = CaptureSessionController(
        drafts,
        FakeLexicalProvider(),
        FakeLearningItemRepository(),
      );

      expect(await controller.restore(), isTrue);
      expect(controller.state, isA<CaptureReconciling>());
      expect(
        (controller.state as CaptureReconciling).submission.submissionId,
        'submission-1',
      );
    },
  );

  test(
    'restored authored draft reruns Library check and unblocks save',
    () async {
      final gate = Completer<void>();
      final drafts = FakeCaptureDraftRepository()
        ..saved = const CaptureDraft(
          content: 'on the record',
          meaning: 'officially',
          meaningRevision: 1,
          meaningConfirmedRevision: 1,
        );
      final items = FakeLearningItemRepository()..matchGate = gate;
      final controller = CaptureSessionController(
        drafts,
        FakeLexicalProvider(),
        items,
        Duration.zero,
      );

      await controller.restore();
      expect(controller.state, isA<CaptureProduction>());
      expect(controller.libraryOutcome, isA<LibraryPending>());

      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect(controller.libraryOutcome, isA<LibraryNoMatch>());
      expect(
        await controller.completeDiscovery(deferProduction: true),
        isNotNull,
      );
    },
  );

  test('invalid restored content returns to editable Entry', () async {
    final drafts = FakeCaptureDraftRepository()
      ..saved = const CaptureDraft(
        content: '...',
        meaning: 'punctuation only',
        meaningRevision: 1,
        meaningConfirmedRevision: 1,
      );
    final controller = CaptureSessionController(
      drafts,
      FakeLexicalProvider(),
      FakeLearningItemRepository(),
      Duration.zero,
    );

    await controller.restore();
    await Future<void>.delayed(Duration.zero);
    expect(await controller.completeDiscovery(deferProduction: true), isNull);

    expect(controller.state, isA<CaptureEntry>());
    expect(
      controller.contentError,
      'Enter language beyond surrounding punctuation.',
    );
  });

  test(
    'lexical result is usable while Library matching remains pending',
    () async {
      final matchGate = Completer<void>();
      final items = FakeLearningItemRepository()..matchGate = matchGate;
      final controller = CaptureSessionController(
        FakeCaptureDraftRepository(),
        FakeLexicalProvider(),
        items,
      );
      await controller.restore();
      controller.updateContent('record');

      final discovery = controller.discover();
      await Future<void>.delayed(Duration.zero);

      expect(controller.state, isA<CaptureVocabularySenses>());
      expect(
        (controller.state as CaptureVocabularySenses).library,
        isA<LibraryPending>(),
      );
      expect(
        (controller.state as CaptureVocabularySenses).lookup?.senses,
        hasLength(2),
      );

      matchGate.complete();
      await discovery;
      expect(
        (controller.state as CaptureVocabularySenses).library,
        isA<LibraryNoMatch>(),
      );
    },
  );

  test(
    'late exact match preserves authored work and opens Re-encounter',
    () async {
      final matchGate = Completer<void>();
      final existing = learningItem(
        content: 'record',
        meaning: 'saved meaning',
      );
      final items = FakeLearningItemRepository(initialItems: [existing])
        ..matchGate = matchGate;
      final controller = CaptureSessionController(
        FakeCaptureDraftRepository(),
        FakeLexicalProvider(),
        items,
      );
      await controller.restore();
      controller.updateContent('record');
      final discovery = controller.discover();
      await Future<void>.delayed(Duration.zero);
      controller.updateMeaning('my authored meaning');

      matchGate.complete();
      await discovery;

      expect(controller.state, isA<CaptureReEncounter>());
      expect(controller.draft.meaning, 'my authored meaning');
    },
  );

  test(
    'manual meaning buffer survives provider selection and return',
    () async {
      final controller = await _vocabularyController();
      controller.chooseManualMeaning();
      controller.updateMeaning('my own explanation');
      final sense = controller.lookup!.senses.first;

      controller.selectSense(sense);
      expect(controller.draft.meaning, sense.definition);
      expect(controller.draft.manualMeaningBuffer, 'my own explanation');

      controller.chooseManualMeaning();
      expect(controller.draft.meaning, 'my own explanation');
    },
  );

  test(
    'restored manual kind override survives subsequent content edits',
    () async {
      final drafts = FakeCaptureDraftRepository()
        ..saved = const CaptureDraft(
          kind: LearningItemKind.vocabulary,
          kindWasOverridden: true,
          content: 'on the record',
        );
      final controller = CaptureSessionController(
        drafts,
        FakeLexicalProvider(),
        FakeLearningItemRepository(),
        Duration.zero,
      );

      await controller.restore();
      controller.updateContent('on the permanent record');

      expect(controller.draft.kind, LearningItemKind.vocabulary);
      expect(controller.kindWasOverridden, isTrue);
      await controller.flush();
      expect(drafts.saved!.kindWasOverridden, isTrue);
    },
  );

  test(
    'edited provider copy requires inline replacement confirmation',
    () async {
      final controller = await _vocabularyController();
      controller.selectSense(controller.lookup!.senses.first);
      controller.updateMeaning('my edited copy');

      controller.selectSense(controller.lookup!.senses.last);

      final state = controller.state as CaptureVocabularySenses;
      expect(state.meaningChoice.kind, MeaningChoiceKind.replacementPending);
      expect(controller.draft.meaning, 'my edited copy');

      controller.replaceMeaning();
      expect(controller.draft.meaning, 'To preserve information.');
    },
  );

  test(
    'type change preserves production but invalidates confirmations',
    () async {
      final controller = await _vocabularyController();
      controller.selectSense(controller.lookup!.senses.first);
      expect(controller.continueToProduction(), isTrue);
      controller.updateProduction('I kept a record.');
      expect(controller.draft.isProductionConfirmed, isTrue);

      controller.updateKind(LearningItemKind.expression);

      expect(controller.draft.production, 'I kept a record.');
      expect(controller.draft.isMeaningConfirmed, isFalse);
      expect(controller.draft.isProductionConfirmed, isFalse);
    },
  );

  test(
    'successful save flushes prepared and attempted checkpoints first',
    () async {
      final drafts = FakeCaptureDraftRepository();
      final controller = await _vocabularyController(drafts: drafts);
      controller.selectSense(controller.lookup!.senses.first);
      expect(controller.continueToProduction(), isTrue);
      controller.updateProduction('I kept a record.');

      final item = await controller.completeDiscovery();

      expect(item, isNotNull);
      expect(controller.state, isA<CaptureDiscovered>());
      expect(item!.isDueAt(DateTime.utc(2026, 8, 30, 20)), isFalse);
      expect(
        drafts.written
            .map((draft) => draft.submissionCheckpoint?.status)
            .whereType<DiscoverySubmissionCheckpointStatus>(),
        containsAllInOrder([
          DiscoverySubmissionCheckpointStatus.prepared,
          DiscoverySubmissionCheckpointStatus.attempted,
        ]),
      );
    },
  );

  test('successful save cancels an older queued draft autosave', () async {
    final drafts = FakeCaptureDraftRepository();
    final controller = CaptureSessionController(
      drafts,
      FakeLexicalProvider(),
      FakeLearningItemRepository(),
      const Duration(milliseconds: 30),
    );
    await controller.restore();
    controller.updateContent('on the record');
    await controller.discover();
    controller.updateMeaning('officially');
    expect(controller.continueToProduction(), isTrue);
    controller.updateProduction('I kept it on the record.');

    expect(await controller.completeDiscovery(), isNotNull);
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(drafts.saved, isNull);
  });

  test(
    'failed post-save clear advances the next draft revision epoch',
    () async {
      final drafts = FakeCaptureDraftRepository()..shouldFailClear = true;
      final controller = await _vocabularyController(drafts: drafts);
      controller.selectSense(controller.lookup!.senses.first);
      expect(controller.continueToProduction(), isTrue);

      expect(
        await controller.completeDiscovery(deferProduction: true),
        isNotNull,
      );
      final tombstoneRevision = controller.draft.draftRevision;
      expect(tombstoneRevision, greaterThan(0));
      expect(controller.draft.submissionCheckpoint, isNull);

      controller.captureAnother();
      controller.updateContent('next capture');
      await controller.flush();

      expect(controller.draft.draftRevision, greaterThan(tombstoneRevision));
      expect(drafts.saved!.content, 'next capture');
    },
  );

  test('backend field validation returns to an editable phase', () async {
    final drafts = FakeCaptureDraftRepository();
    final items = FakeLearningItemRepository()
      ..discoveryFailure = const DiscoveryFailure(
        DiscoveryFailureCode.discoveryValidationRejected,
        metadata: DiscoveryFailureMetadata(field: DiscoveryFailureField.source),
      );
    final controller = CaptureSessionController(
      drafts,
      FakeLexicalProvider(),
      items,
      Duration.zero,
    );
    await controller.restore();
    controller.updateContent('on the record');
    await controller.discover();
    controller.updateMeaning('officially');
    expect(controller.continueToProduction(), isTrue);

    expect(await controller.completeDiscovery(deferProduction: true), isNull);

    expect(controller.state, isA<CaptureExpressionMeaning>());
    expect(controller.draft.submissionCheckpoint, isNull);
    expect(drafts.saved!.submissionCheckpoint, isNull);
    expect(controller.saveError, 'Some Discovery details need correction.');
  });

  test('deferred production saves an item due immediately', () async {
    final items = FakeLearningItemRepository();
    final controller = CaptureSessionController(
      FakeCaptureDraftRepository(),
      FakeLexicalProvider(),
      items,
    );
    await controller.restore();
    controller.updateContent('on the record');
    await controller.discover();
    controller.updateMeaning('officially');
    expect(controller.continueToProduction(), isTrue);

    final item = await controller.completeDiscovery(deferProduction: true);

    expect(item, isNotNull);
    expect(item!.isDueAt(item.nextReviewAt), isTrue);
    expect(item.firstProduction, isNull);
  });

  test('unknown outcome retries the identical frozen submission', () async {
    final items = FakeLearningItemRepository()
      ..discoveryFailure = const DiscoveryFailure(
        DiscoveryFailureCode.discoveryOutcomeUnknown,
      );
    final controller = await _vocabularyController(items: items);
    controller.selectSense(controller.lookup!.senses.first);
    expect(controller.continueToProduction(), isTrue);
    controller.updateProduction('I kept a record.');

    expect(await controller.completeDiscovery(), isNull);
    final failed = controller.state as CaptureReconciling;
    final frozenId = failed.submission.submissionId;
    items.discoveryFailure = null;

    final item = await controller.retrySubmission();

    expect(item, isNotNull);
    expect(item!.id, 'discovery-$frozenId');
    expect(items.discoverySubmissions.keys, [frozenId]);
  });

  test(
    'multiple matches start unselected and reveal only selected meaning',
    () async {
      final first = learningItem(
        id: 'one',
        content: 'record',
        meaning: 'account',
      );
      final second = learningItem(
        id: 'two',
        content: 'record',
        meaning: 'best',
      );
      final controller = CaptureSessionController(
        FakeCaptureDraftRepository(),
        FakeLexicalProvider(),
        FakeLearningItemRepository(initialItems: [first, second]),
      );
      await controller.restore();
      controller.updateContent('record');
      await controller.discover();

      var state = controller.state as CaptureReEncounter;
      expect(state.choice.kind, ReEncounterChoiceKind.unselected);
      controller.selectReEncounterItem(second);
      controller.showMeaning();

      state = controller.state as CaptureReEncounter;
      expect(state.choice.kind, ReEncounterChoiceKind.revealed);
      expect(state.choice.item?.id, 'two');
    },
  );
}

Future<CaptureSessionController> _vocabularyController({
  FakeCaptureDraftRepository? drafts,
  FakeLearningItemRepository? items,
}) async {
  final controller = CaptureSessionController(
    drafts ?? FakeCaptureDraftRepository(),
    FakeLexicalProvider(),
    items ?? FakeLearningItemRepository(),
  );
  await controller.restore();
  controller.updateContent('record');
  await controller.discover();
  expect(controller.state, isA<CaptureVocabularySenses>());
  return controller;
}
