import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/discovery_validation.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

void main() {
  group('DiscoveryValidation', () {
    test('requires content and meaning at database-compatible limits', () {
      expect(
        DiscoveryValidation.validateContent('  '),
        'Enter the language you encountered.',
      );
      expect(
        DiscoveryValidation.validateMeaning('  '),
        'Add the meaning you encountered.',
      );
      expect(DiscoveryValidation.validateContent('w' * 2001), isNotNull);
      expect(DiscoveryValidation.validateMeaning('m' * 4001), isNotNull);
      expect(
        DiscoveryValidation.validateProduction('p' * 10001, required: false),
        isNotNull,
      );
    });

    test('normalizes exact-surface punctuation without stemming', () {
      expect(
        DiscoveryValidation.surfaceMatchKey(' “L’arc — en  ciel!” '),
        "l'arc-en ciel",
      );
      expect(DiscoveryValidation.surfaceMatchKey('records'), 'records');
      expect(DiscoveryValidation.surfaceMatchKey('record'), 'record');
    });

    test('suggests vocabulary only for one nonblank token', () {
      expect(
        DiscoveryValidation.suggestKind('record'),
        LearningItemKind.vocabulary,
      );
      expect(
        DiscoveryValidation.suggestKind('on the record'),
        LearningItemKind.expression,
      );
    });
  });
}
