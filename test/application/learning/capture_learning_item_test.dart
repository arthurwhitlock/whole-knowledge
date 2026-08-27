import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/learning/capture_learning_item.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

void main() {
  test('requires non-blank captured language', () {
    expect(
      CaptureLearningItemValidator.validateContent('  '),
      'Enter the language you encountered.',
    );
    expect(CaptureLearningItemValidator.validateContent('bonjour'), isNull);
  });

  test('normalizes whitespace and empty optional fields', () {
    const capture = CaptureLearningItem(
      kind: LearningItemKind.vocabulary,
      content: '  pourtant  ',
      partOfSpeech: ' Adj ',
      meaning: '  however ',
      context: '   ',
    );

    final normalized = capture.normalized();

    expect(normalized.content, 'pourtant');
    expect(normalized.partOfSpeech, 'adjective');
    expect(normalized.meaning, 'however');
    expect(normalized.context, isNull);
  });

  test('preserves safe unknown part-of-speech values', () {
    const capture = CaptureLearningItem(
      kind: LearningItemKind.vocabulary,
      content: 'bonjour',
      partOfSpeech: 'Interjection',
    );

    expect(capture.normalized().partOfSpeech, 'interjection');
    expect(
      CaptureLearningItemValidator.validatePartOfSpeech('p' * 81),
      'Keep the part of speech under 80 characters.',
    );
  });

  test('validates optional fields at database-compatible limits', () {
    expect(
      CaptureLearningItemValidator.validateMeaning('m' * 4001),
      'Keep the meaning under 4,000 characters.',
    );
    expect(
      CaptureLearningItemValidator.validateContext('c' * 4001),
      'Keep the context under 4,000 characters.',
    );
    expect(
      CaptureLearningItemValidator.validateSource('s' * 1001),
      'Keep the source under 1,000 characters.',
    );
  });
}
