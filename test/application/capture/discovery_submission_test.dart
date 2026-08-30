import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

void main() {
  test(
    'normalizes immutable payload without changing allow-existing intent',
    () {
      const submission = DiscoverySubmission(
        submissionId: 'submission-1',
        kind: LearningItemKind.vocabulary,
        content: '  Record ',
        partOfSpeech: ' N ',
        meaning: '  a stored account ',
        context: '   ',
        firstProduction: ' I kept a record. ',
        allowExistingSurface: true,
      );

      final normalized = submission.normalized();

      expect(normalized.content, 'Record');
      expect(normalized.partOfSpeech, 'noun');
      expect(normalized.meaning, 'a stored account');
      expect(normalized.context, isNull);
      expect(normalized.firstProduction, 'I kept a record.');
      expect(normalized.allowExistingSurface, isTrue);
    },
  );

  test('payload comparison includes the submission ID and every field', () {
    const first = DiscoverySubmission(
      submissionId: 'submission-1',
      kind: LearningItemKind.expression,
      content: 'on the record',
      meaning: 'officially',
      allowExistingSurface: false,
    );

    expect(first.hasSamePayload(first), isTrue);
    expect(
      first.hasSamePayload(
        const DiscoverySubmission(
          submissionId: 'submission-1',
          kind: LearningItemKind.expression,
          content: 'on the record',
          meaning: 'publicly',
          allowExistingSurface: false,
        ),
      ),
      isFalse,
    );
  });
}
