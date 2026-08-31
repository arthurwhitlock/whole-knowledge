import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

import '../../../support/fakes.dart';
import 'capture_test_harness.dart';

void main() {
  testWidgets('sole match is selected but its answer stays hidden', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final item = learningItem(
      content: 'record',
      meaning: 'secret saved meaning',
      firstProduction: 'secret saved production',
      partOfSpeech: 'noun',
      source: 'Field notes',
    );
    final harness = await _reEncounterHarness([item]);
    await pumpCapture(tester, harness.controller, onTestItem: (_) => true);

    expect(find.text('secret saved meaning'), findsNothing);
    expect(find.textContaining('secret saved production'), findsNothing);
    expect(find.bySemanticsLabel(RegExp('secret saved')), findsNothing);
    expect(find.byKey(const ValueKey('test-myself')), findsOneWidget);
    expect(find.text('Show meaning'), findsOneWidget);
    expect(find.byKey(const ValueKey('learn-another-sense')), findsOneWidget);
    semantics.dispose();
  });

  testWidgets(
    'multiple matches start unselected with one shared action group',
    (tester) async {
      final first = learningItem(
        id: 'first',
        content: 'record',
        meaning: 'first answer',
        partOfSpeech: 'noun',
      );
      final second = learningItem(
        id: 'second',
        content: 'record',
        meaning: 'second answer',
        partOfSpeech: 'verb',
      );
      final harness = await _reEncounterHarness([first, second]);
      await pumpCapture(tester, harness.controller, onTestItem: (_) => true);

      expect(find.byKey(const ValueKey('test-myself')), findsNothing);
      expect(find.text('Show meaning'), findsNothing);
      expect(find.byKey(const ValueKey('learn-another-sense')), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RegExp('Noun|noun')));
      await tester.pump();
      expect(find.byKey(const ValueKey('test-myself')), findsOneWidget);
      expect(find.byKey(const ValueKey('learn-another-sense')), findsOneWidget);
    },
  );

  testWidgets('show, hide, selection change, and Test myself are read-only', (
    tester,
  ) async {
    final first = learningItem(
      id: 'first',
      content: 'record',
      meaning: 'first answer',
      partOfSpeech: 'noun',
    );
    final second = learningItem(
      id: 'second',
      content: 'record',
      meaning: 'second answer',
      partOfSpeech: 'verb',
    );
    final harness = await _reEncounterHarness([first, second]);
    Object? tested;
    await pumpCapture(
      tester,
      harness.controller,
      onTestItem: (item) {
        tested = item;
        return true;
      },
    );
    await tester.tap(
      find.bySemanticsLabel(RegExp('noun', caseSensitive: false)),
    );
    await tester.pump();
    await tester.tap(find.text('Show meaning'));
    await tester.pump();
    expect(find.text('first answer'), findsOneWidget);
    expect(harness.items.items.first.reviewCount, 0);

    await tester.tap(find.text('Hide meaning'));
    await tester.pump();
    expect(find.text('first answer'), findsNothing);
    await tester.tap(
      find.bySemanticsLabel(RegExp('verb', caseSensitive: false)),
    );
    await tester.pump();
    expect(find.text('second answer'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('test-myself')));
    expect(tested, same(second));
    expect(harness.items.items.every((item) => item.reviewCount == 0), isTrue);
  });
}

Future<CaptureTestHarness> _reEncounterHarness(List<LearningItem> items) async {
  final harness = await CaptureTestHarness.create(initialItems: items);
  harness.controller.updateContent('record');
  await harness.controller.discover();
  return harness;
}
