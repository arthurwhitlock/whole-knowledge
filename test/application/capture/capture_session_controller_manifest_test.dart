import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/capture_session_state.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

import '../../support/fakes.dart';

void main() {
  group('manifest content validation', () {
    final cases = <({String name, String value, bool valid})>[
      (name: 'empty', value: '', valid: false),
      (name: 'spaces', value: '   ', valid: false),
      (name: 'newline', value: '\n', valid: false),
      (name: 'tab', value: '\t', valid: false),
      (name: 'oversized', value: List.filled(2001, 'a').join(), valid: false),
      (name: 'one character', value: 'a', valid: true),
      (
        name: 'exact maximum',
        value: List.filled(2000, 'a').join(),
        valid: true,
      ),
      (name: 'hyphenated', value: 'well-being', valid: true),
      (name: 'apostrophe', value: "learner's", valid: true),
      (name: 'expression', value: 'on the record', valid: true),
    ];
    for (final entry in cases) {
      test('content ${entry.name}', () async {
        final controller = await _controller();
        controller.updateContent(entry.value);
        await controller.discover();
        expect(controller.contentError == null, entry.valid);
        expect(controller.state is CaptureEntry, !entry.valid);
        controller.dispose();
      });
    }
  });

  group('manifest type suggestion', () {
    final cases = <({String name, String value, LearningItemKind kind})>[
      (
        name: 'simple token',
        value: 'record',
        kind: LearningItemKind.vocabulary,
      ),
      (
        name: 'hyphen token',
        value: 'well-being',
        kind: LearningItemKind.vocabulary,
      ),
      (
        name: 'apostrophe token',
        value: "don't",
        kind: LearningItemKind.vocabulary,
      ),
      (
        name: 'punctuated token',
        value: 'record!',
        kind: LearningItemKind.vocabulary,
      ),
      (
        name: 'trimmed token',
        value: ' record ',
        kind: LearningItemKind.vocabulary,
      ),
      (
        name: 'two words',
        value: 'on record',
        kind: LearningItemKind.expression,
      ),
      (
        name: 'many spaces',
        value: 'on   record',
        kind: LearningItemKind.expression,
      ),
      (
        name: 'newline words',
        value: 'on\nrecord',
        kind: LearningItemKind.expression,
      ),
      (
        name: 'tab words',
        value: 'on\trecord',
        kind: LearningItemKind.expression,
      ),
      (name: 'blank default', value: '', kind: LearningItemKind.expression),
    ];
    for (final entry in cases) {
      test('suggests ${entry.name}', () async {
        final controller = await _controller();
        controller.updateContent(entry.value);
        expect(controller.draft.kind, entry.kind);
        expect(controller.suggestedKind, entry.kind);
        controller.dispose();
      });
    }
  });

  group('manifest draft migration and round trip', () {
    final cases =
        <
          ({
            String name,
            Map<String, Object?> json,
            void Function(CaptureDraft) verify,
          })
        >[
          (
            name: 'v1 term only',
            json: {'version': 1, 'content': 'record'},
            verify: (draft) => expect(draft.content, 'record'),
          ),
          (
            name: 'v1 vocabulary kind',
            json: {'version': 1, 'kind': 'vocabulary'},
            verify: (draft) => expect(draft.kind, LearningItemKind.vocabulary),
          ),
          (
            name: 'v1 meaning buffer',
            json: {'version': 1, 'meaning': 'saved'},
            verify: (draft) => expect(draft.manualMeaningBuffer, 'saved'),
          ),
          (
            name: 'v1 meaning unconfirmed',
            json: {'version': 1, 'meaning': 'saved'},
            verify: (draft) => expect(draft.isMeaningConfirmed, isFalse),
          ),
          (
            name: 'v1 context',
            json: {'version': 1, 'context': 'a context'},
            verify: (draft) => expect(draft.context, 'a context'),
          ),
          (
            name: 'v1 source',
            json: {'version': 1, 'source': 'a source'},
            verify: (draft) => expect(draft.source, 'a source'),
          ),
          (
            name: 'v2 revision',
            json: {'version': 2, 'draftRevision': 7},
            verify: (draft) => expect(draft.draftRevision, 7),
          ),
          (
            name: 'v2 production',
            json: {'version': 2, 'production': 'I used it.'},
            verify: (draft) => expect(draft.production, 'I used it.'),
          ),
          (
            name: 'v2 confirmation stamps',
            json: {
              'version': 2,
              'meaning': 'saved',
              'meaningRevision': 3,
              'meaningConfirmedRevision': 3,
              'production': 'used',
              'productionConfirmedMeaningRevision': 3,
            },
            verify: (draft) {
              expect(draft.isMeaningConfirmed, isTrue);
              expect(draft.isProductionConfirmed, isTrue);
            },
          ),
          (
            name: 'v2 lossless round trip',
            json: const CaptureDraft(
              content: 'record',
              meaning: 'saved',
              context: 'context',
              source: 'source',
              production: 'production',
            ).toJson(),
            verify: (draft) =>
                expect(draft.toJson(), containsPair('version', 2)),
          ),
        ];
    for (final entry in cases) {
      test(entry.name, () {
        entry.verify(CaptureDraft.fromJson(entry.json));
      });
    }
  });

  group('manifest authored revision invalidation', () {
    test('meaning edit advances revision', () async {
      final controller = await _restoredAuthored();
      final before = controller.draft.meaningRevision;
      controller.updateMeaning('changed');
      expect(controller.draft.meaningRevision, before + 1);
      controller.dispose();
    });
    test('meaning edit confirms current revision', () async {
      final controller = await _restoredAuthored();
      controller.updateMeaning('changed');
      expect(controller.draft.isMeaningConfirmed, isTrue);
      controller.dispose();
    });
    test('blank meaning clears confirmation', () async {
      final controller = await _restoredAuthored();
      controller.updateMeaning(' ');
      expect(controller.draft.isMeaningConfirmed, isFalse);
      controller.dispose();
    });
    test('production edit stamps meaning revision', () async {
      final controller = await _restoredAuthored();
      controller.updateProduction('I used it.');
      expect(controller.draft.isProductionConfirmed, isTrue);
      controller.dispose();
    });
    test('blank production clears confirmation', () async {
      final controller = await _restoredAuthored();
      controller.updateProduction('I used it.');
      controller.updateProduction('');
      expect(controller.draft.isProductionConfirmed, isFalse);
      controller.dispose();
    });
    test('context edit preserves meaning confirmation', () async {
      final controller = await _restoredAuthored();
      controller.updateEncounterDetails(context: 'new context');
      expect(controller.draft.isMeaningConfirmed, isTrue);
      controller.dispose();
    });
    test('source edit preserves meaning confirmation', () async {
      final controller = await _restoredAuthored();
      controller.updateEncounterDetails(source: 'new source');
      expect(controller.draft.isMeaningConfirmed, isTrue);
      controller.dispose();
    });
    test('type edit invalidates both confirmations', () async {
      final controller = await _restoredAuthored(production: 'I used it.');
      controller.updateKind(LearningItemKind.vocabulary);
      expect(controller.draft.isMeaningConfirmed, isFalse);
      expect(controller.draft.isProductionConfirmed, isFalse);
      controller.dispose();
    });
    test('content edit returns Entry and invalidates meaning', () async {
      final controller = await _restoredAuthored();
      controller.updateContent('different');
      expect(controller.state, isA<CaptureEntry>());
      expect(controller.draft.isMeaningConfirmed, isFalse);
      controller.dispose();
    });
    test('part of speech edit invalidates production only', () async {
      final controller = await _restoredAuthored(production: 'I used it.');
      controller.update(controller.draft.copyWith(partOfSpeech: 'noun'));
      expect(controller.draft.isMeaningConfirmed, isTrue);
      expect(controller.draft.isProductionConfirmed, isFalse);
      controller.dispose();
    });
  });

  group('manifest invalid transition safety', () {
    test('blank meaning cannot continue', () async {
      final controller = await _controller();
      expect(controller.continueToProduction(), isFalse);
      controller.dispose();
    });
    test('blank meaning cannot confirm', () async {
      final controller = await _controller();
      controller.confirmMeaning();
      expect(controller.draft.isMeaningConfirmed, isFalse);
      controller.dispose();
    });
    test('blank production cannot confirm', () async {
      final controller = await _controller();
      controller.confirmProduction();
      expect(controller.draft.isProductionConfirmed, isFalse);
      controller.dispose();
    });
    test('Entry ignores show meaning', () async {
      final controller = await _controller();
      controller.showMeaning();
      expect(controller.state, isA<CaptureEntry>());
      controller.dispose();
    });
    test('Entry ignores hide meaning', () async {
      final controller = await _controller();
      controller.hideMeaning();
      expect(controller.state, isA<CaptureEntry>());
      controller.dispose();
    });
    test('Entry ignores unrelated reencounter selection', () async {
      final controller = await _controller();
      controller.selectReEncounterItem(learningItem());
      expect(controller.selectedReEncounterItem, isNull);
      controller.dispose();
    });
    test('Entry ignores Learn another sense', () async {
      final controller = await _controller();
      controller.learnAnotherSense();
      expect(controller.state, isA<CaptureEntry>());
      controller.dispose();
    });
    test('retry without checkpoint is inert', () async {
      final controller = await _controller();
      expect(await controller.retrySubmission(), isNull);
      controller.dispose();
    });
    test('Done outside completion is inert', () async {
      final controller = await _controller();
      controller.done();
      expect(controller.state, isA<CaptureEntry>());
      controller.dispose();
    });
    test('Capture another outside completion is inert', () async {
      final controller = await _controller();
      controller.captureAnother();
      expect(controller.state, isA<CaptureEntry>());
      controller.dispose();
    });
  });

  group('manifest vocabulary meaning path', () {
    test('provider selection copies meaning', () async {
      final controller = await _vocabulary();
      controller.selectSense(controller.lookup!.senses.first);
      expect(controller.draft.meaning, 'A stored account.');
      controller.dispose();
    });
    test('provider selection copies POS', () async {
      final controller = await _vocabulary();
      controller.selectSense(controller.lookup!.senses.first);
      expect(controller.draft.partOfSpeech, 'noun');
      controller.dispose();
    });
    test('manual choice restores empty buffer', () async {
      final controller = await _vocabulary();
      controller.chooseManualMeaning();
      expect(controller.draft.meaning, isEmpty);
      controller.dispose();
    });
    test('manual buffer survives provider choice', () async {
      final controller = await _vocabulary();
      controller.chooseManualMeaning();
      controller.updateMeaning('manual');
      controller.selectSense(controller.lookup!.senses.first);
      expect(controller.draft.manualMeaningBuffer, 'manual');
      controller.dispose();
    });
    test('edited provider proposes replacement', () async {
      final controller = await _vocabulary();
      controller.selectSense(controller.lookup!.senses.first);
      controller.updateMeaning('edited');
      controller.selectSense(controller.lookup!.senses.last);
      expect(
        (controller.state as CaptureVocabularySenses).meaningChoice.kind,
        MeaningChoiceKind.replacementPending,
      );
      controller.dispose();
    });
    test('Keep editing preserves edited copy', () async {
      final controller = await _replacementPending();
      controller.keepEditingMeaning();
      expect(controller.draft.meaning, 'edited');
      controller.dispose();
    });
    test('Replace applies proposed sense', () async {
      final controller = await _replacementPending();
      controller.replaceMeaning();
      expect(controller.draft.meaning, 'To preserve information.');
      controller.dispose();
    });
    test('valid provider meaning continues', () async {
      final controller = await _vocabulary();
      controller.selectSense(controller.lookup!.senses.first);
      expect(controller.continueToProduction(), isTrue);
      controller.dispose();
    });
    test('Back from vocabulary returns Entry', () async {
      final controller = await _vocabulary();
      controller.back();
      expect(controller.state, isA<CaptureEntry>());
      controller.dispose();
    });
    test('lexical retry replaces a failed result', () async {
      final lexical = FakeLexicalProvider()
        ..error = const DiscoveryFailure(
          DiscoveryFailureCode.lexicalServiceUnavailable,
        );
      final controller = await _controller(lexical: lexical);
      controller.updateContent('record');
      await controller.discover();
      lexical.error = null;
      await controller.retryLexical();
      expect(controller.lookup, isNotNull);
      controller.dispose();
    });
  });

  group('manifest reencounter behavior', () {
    test('sole match auto-selects', () async {
      final controller = await _reencounter([learningItem(content: 'record')]);
      expect(controller.selectedReEncounterItem, isNotNull);
      controller.dispose();
    });
    test('multiple matches start unselected', () async {
      final controller = await _reencounter(_twoMatches());
      expect(controller.selectedReEncounterItem, isNull);
      controller.dispose();
    });
    test('matching selection succeeds', () async {
      final matches = _twoMatches();
      final controller = await _reencounter(matches);
      controller.selectReEncounterItem(matches.last);
      expect(controller.selectedReEncounterItem, same(matches.last));
      controller.dispose();
    });
    test('unrelated selection is ignored', () async {
      final controller = await _reencounter(_twoMatches());
      controller.selectReEncounterItem(learningItem(id: 'outsider'));
      expect(controller.selectedReEncounterItem, isNull);
      controller.dispose();
    });
    test('Show meaning marks reveal only', () async {
      final controller = await _reencounter([learningItem(content: 'record')]);
      controller.showMeaning();
      expect(
        (controller.state as CaptureReEncounter).choice.kind,
        ReEncounterChoiceKind.revealed,
      );
      controller.dispose();
    });
    test('Hide meaning returns selected', () async {
      final controller = await _reencounter([learningItem(content: 'record')]);
      controller.showMeaning();
      controller.hideMeaning();
      expect(
        (controller.state as CaptureReEncounter).choice.kind,
        ReEncounterChoiceKind.selected,
      );
      controller.dispose();
    });
    test('new selection collapses reveal', () async {
      final matches = _twoMatches();
      final controller = await _reencounter(matches);
      controller.selectReEncounterItem(matches.first);
      controller.showMeaning();
      controller.selectReEncounterItem(matches.last);
      expect(
        (controller.state as CaptureReEncounter).choice.kind,
        ReEncounterChoiceKind.selected,
      );
      controller.dispose();
    });
    test('Learn another resumes vocabulary', () async {
      final controller = await _reencounter([learningItem(content: 'record')]);
      controller.learnAnotherSense();
      expect(controller.state, isA<CaptureVocabularySenses>());
      controller.dispose();
    });
    test('Learn another preserves authored meaning', () async {
      final controller = await _reencounter([learningItem(content: 'record')]);
      controller.updateMeaning('authored before interruption');
      controller.learnAnotherSense();
      expect(controller.draft.meaning, 'authored before interruption');
      controller.dispose();
    });
    test('reveal writes no repository data', () async {
      final items = FakeLearningItemRepository(
        initialItems: [learningItem(content: 'record')],
      );
      final controller = await _controller(items: items);
      controller.updateContent('record');
      await controller.discover();
      controller.showMeaning();
      expect(items.discoverySubmissions, isEmpty);
      expect(items.items.single.reviewCount, 0);
      controller.dispose();
    });
  });

  group('manifest persistence and reconciliation', () {
    test('deferred create is due now', () async {
      final controller = await _expressionProduction();
      final item = await controller.completeDiscovery(deferProduction: true);
      expect(item!.isDueAt(item.nextReviewAt), isTrue);
      controller.dispose();
    });
    test('completed production schedules later', () async {
      final controller = await _expressionProduction(production: 'I used it.');
      final item = await controller.completeDiscovery();
      expect(item!.isDueAt(DateTime.utc(2026, 8, 30, 20)), isFalse);
      controller.dispose();
    });
    test('prepared checkpoint is written', () async {
      final drafts = FakeCaptureDraftRepository();
      final controller = await _expressionProduction(
        drafts: drafts,
        production: 'I used it.',
      );
      await controller.completeDiscovery();
      expect(
        drafts.written.map((draft) => draft.submissionCheckpoint?.status),
        contains(DiscoverySubmissionCheckpointStatus.prepared),
      );
      controller.dispose();
    });
    test('attempted checkpoint is written', () async {
      final drafts = FakeCaptureDraftRepository();
      final controller = await _expressionProduction(
        drafts: drafts,
        production: 'I used it.',
      );
      await controller.completeDiscovery();
      expect(
        drafts.written.map((draft) => draft.submissionCheckpoint?.status),
        contains(DiscoverySubmissionCheckpointStatus.attempted),
      );
      controller.dispose();
    });
    test('unknown outcome enters reconciliation', () async {
      final items = FakeLearningItemRepository()
        ..discoveryFailure = const DiscoveryFailure(
          DiscoveryFailureCode.discoveryOutcomeUnknown,
        );
      final controller = await _expressionProduction(
        items: items,
        production: 'I used it.',
      );
      await controller.completeDiscovery();
      expect(controller.state, isA<CaptureReconciling>());
      controller.dispose();
    });
    test('unknown retry keeps submission ID', () async {
      final items = FakeLearningItemRepository()
        ..discoveryFailure = const DiscoveryFailure(
          DiscoveryFailureCode.discoveryOutcomeUnknown,
        );
      final controller = await _expressionProduction(
        items: items,
        production: 'I used it.',
      );
      await controller.completeDiscovery();
      final before =
          controller.draft.submissionCheckpoint!.submission.submissionId;
      items.discoveryFailure = null;
      await controller.retrySubmission();
      expect(items.discoverySubmissions.keys.single, before);
      controller.dispose();
    });
    test('Library pending gates completion', () async {
      final gate = Completer<void>();
      final items = FakeLearningItemRepository()..matchGate = gate;
      final controller = await _controller(items: items);
      controller.updateContent('on the record');
      final discovery = controller.discover();
      await Future<void>.delayed(Duration.zero);
      controller.updateMeaning('officially');
      controller.continueToProduction();
      expect(await controller.completeDiscovery(deferProduction: true), isNull);
      expect(controller.saveError, 'Check your Library before saving.');
      gate.complete();
      await discovery;
      controller.dispose();
    });
    test('Library failure gates completion', () async {
      final items = FakeLearningItemRepository()..shouldFailMatches = true;
      final controller = await _controller(items: items);
      controller.updateContent('on the record');
      await controller.discover();
      controller.updateMeaning('officially');
      controller.continueToProduction();
      expect(await controller.completeDiscovery(deferProduction: true), isNull);
      expect(controller.saveError, 'Retry the Library check before saving.');
      controller.dispose();
    });
    test('same surface returns Re-encounter before create', () async {
      final controller = await _controller(
        items: FakeLearningItemRepository(
          initialItems: [learningItem(content: 'on the record')],
        ),
      );
      controller.updateContent('on the record');
      await controller.discover();
      expect(controller.state, isA<CaptureReEncounter>());
      controller.dispose();
    });
    test('Done resets successful completion to Entry', () async {
      final controller = await _expressionProduction();
      await controller.completeDiscovery(deferProduction: true);
      controller.done();
      expect(controller.state, isA<CaptureEntry>());
      controller.dispose();
    });
  });

  group('manifest optional authored field validation', () {
    test('oversized context stays in editable meaning phase', () async {
      final items = FakeLearningItemRepository();
      final controller = await _controller(items: items);
      controller.updateContent('on the record');
      await controller.discover();
      controller.updateMeaning('officially');
      controller.updateEncounterDetails(context: 'c' * 4001);

      expect(controller.continueToProduction(), isFalse);
      expect(controller.state, isA<CaptureExpressionMeaning>());
      expect(controller.saveError, 'Keep the context under 4,000 characters.');
      expect(items.discoverySubmissions, isEmpty);
      controller.dispose();
    });

    test('oversized source stays in editable meaning phase', () async {
      final items = FakeLearningItemRepository();
      final controller = await _controller(items: items);
      controller.updateContent('on the record');
      await controller.discover();
      controller.updateMeaning('officially');
      controller.updateEncounterDetails(source: 's' * 1001);

      expect(controller.continueToProduction(), isFalse);
      expect(controller.state, isA<CaptureExpressionMeaning>());
      expect(controller.saveError, 'Keep the source under 1,000 characters.');
      expect(items.discoverySubmissions, isEmpty);
      controller.dispose();
    });

    test('oversized part of speech stays in editable meaning phase', () async {
      final items = FakeLearningItemRepository();
      final controller = await _controller(items: items);
      controller.updateContent('record');
      await controller.discover();
      controller.chooseManualMeaning();
      controller.updateMeaning('a stored account');
      controller.update(controller.draft.copyWith(partOfSpeech: 'p' * 81));

      expect(controller.continueToProduction(), isFalse);
      expect(controller.state, isA<CaptureVocabularySenses>());
      expect(
        controller.saveError,
        'Keep the part of speech under 80 characters.',
      );
      expect(items.discoverySubmissions, isEmpty);
      controller.dispose();
    });
  });
}

Future<CaptureSessionController> _controller({
  FakeCaptureDraftRepository? drafts,
  FakeLexicalProvider? lexical,
  FakeLearningItemRepository? items,
}) async {
  final controller = CaptureSessionController(
    drafts ?? FakeCaptureDraftRepository(),
    lexical ?? FakeLexicalProvider(),
    items ?? FakeLearningItemRepository(),
    Duration.zero,
  );
  await controller.restore();
  return controller;
}

Future<CaptureSessionController> _restoredAuthored({
  String production = '',
}) async {
  final drafts = FakeCaptureDraftRepository()
    ..saved = CaptureDraft(
      content: 'on the record',
      meaning: 'officially',
      manualMeaningBuffer: 'officially',
      production: production,
      meaningRevision: 1,
      meaningConfirmedRevision: 1,
      productionConfirmedMeaningRevision: production.isEmpty ? null : 1,
    );
  return _controller(drafts: drafts);
}

Future<CaptureSessionController> _vocabulary() async {
  final controller = await _controller();
  controller.updateContent('record');
  await controller.discover();
  return controller;
}

Future<CaptureSessionController> _replacementPending() async {
  final controller = await _vocabulary();
  controller.selectSense(controller.lookup!.senses.first);
  controller.updateMeaning('edited');
  controller.selectSense(controller.lookup!.senses.last);
  return controller;
}

Future<CaptureSessionController> _reencounter(
  List<LearningItem> matches,
) async {
  final controller = await _controller(
    items: FakeLearningItemRepository(initialItems: matches),
  );
  controller.updateContent('record');
  await controller.discover();
  return controller;
}

List<LearningItem> _twoMatches() => [
  learningItem(id: 'first', content: 'record', meaning: 'first'),
  learningItem(id: 'second', content: 'record', meaning: 'second'),
];

Future<CaptureSessionController> _expressionProduction({
  FakeCaptureDraftRepository? drafts,
  FakeLearningItemRepository? items,
  String production = '',
}) async {
  final controller = await _controller(drafts: drafts, items: items);
  controller.updateContent('on the record');
  await controller.discover();
  controller.updateMeaning('officially');
  expect(controller.continueToProduction(), isTrue);
  if (production.isNotEmpty) controller.updateProduction(production);
  return controller;
}
