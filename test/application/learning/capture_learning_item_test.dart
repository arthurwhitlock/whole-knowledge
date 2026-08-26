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
      meaning: '  however ',
      context: '   ',
    );

    final normalized = capture.normalized();

    expect(normalized.content, 'pourtant');
    expect(normalized.meaning, 'however');
    expect(normalized.context, isNull);
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
