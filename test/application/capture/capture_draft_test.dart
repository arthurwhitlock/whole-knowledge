import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

void main() {
  test('migrates all authored v1 fields and requires reconfirmation', () {
    final draft = CaptureDraft.fromJson({
      'version': 1,
      'kind': 'vocabulary',
      'content': 'record',
      'partOfSpeech': 'noun',
      'meaning': 'a stored account',
      'context': 'in a meeting',
      'source': 'conversation',
    });

    expect(draft.kind, LearningItemKind.vocabulary);
    expect(draft.manualMeaningBuffer, 'a stored account');
    expect(draft.context, 'in a meeting');
    expect(draft.source, 'conversation');
    expect(draft.isMeaningConfirmed, isFalse);
  });

  test('round trips v2 authored values and frozen checkpoint', () {
    const submission = DiscoverySubmission(
      submissionId: '00000000-0000-4000-8000-000000000001',
      kind: LearningItemKind.vocabulary,
      content: 'record',
      partOfSpeech: 'noun',
      meaning: 'a stored account',
      context: 'meeting',
      source: 'conversation',
      firstProduction: 'I kept a record.',
      allowExistingSurface: false,
    );
    const draft = CaptureDraft(
      draftRevision: 7,
      kind: LearningItemKind.vocabulary,
      content: 'record',
      partOfSpeech: 'noun',
      meaning: 'a stored account',
      manualMeaningBuffer: 'my own explanation',
      production: 'I kept a record.',
      meaningRevision: 3,
      meaningConfirmedRevision: 3,
      productionConfirmedMeaningRevision: 3,
      submissionCheckpoint: DiscoverySubmissionCheckpoint(
        status: DiscoverySubmissionCheckpointStatus.attempted,
        submission: submission,
      ),
    );

    final restored = CaptureDraft.fromJson(draft.toJson());

    expect(restored.toJson(), draft.toJson());
    expect(restored.isMeaningConfirmed, isTrue);
    expect(restored.isProductionConfirmed, isTrue);
  });
}
