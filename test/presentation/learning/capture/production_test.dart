import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

import 'capture_test_harness.dart';

void main() {
  testWidgets('meaning and POS remain visible beside first production', (
    tester,
  ) async {
    final harness = await _productionHarness(vocabulary: true);
    await pumpCapture(tester, harness.controller);

    expect(find.text('A stored account.'), findsOneWidget);
    expect(find.text('noun'), findsOneWidget);
    expect(find.byKey(const ValueKey('first-production')), findsOneWidget);
    expect(find.byKey(const ValueKey('defer-production')), findsOneWidget);
  });

  testWidgets('blank completion focuses the production error and keeps defer', (
    tester,
  ) async {
    final harness = await _productionHarness();
    await pumpCapture(tester, harness.controller);
    await tester.tap(find.byKey(const ValueKey('complete-discovery')));
    await tester.pump();

    expect(
      find.text('Use this language in your own sentence.'),
      findsOneWidget,
    );
    final editor = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('first-production')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editor.focusNode.hasFocus, isTrue);
    expect(find.byKey(const ValueKey('defer-production')), findsOneWidget);
  });

  testWidgets(
    'type change preserves production and requires both confirmations',
    (tester) async {
      final harness = await _productionHarness(vocabulary: true);
      harness.controller.updateProduction('I kept a record.');
      harness.controller.updateKind(LearningItemKind.expression);
      await pumpCapture(tester, harness.controller);

      expect(find.text('“I kept a record.”'), findsOneWidget);
      expect(find.text('Review this meaning for Expression'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('confirm-preserved-production')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('confirm-current-meaning')));
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('confirm-preserved-production')),
      );
      await tester.pump();
      expect(harness.controller.draft.isMeaningConfirmed, isTrue);
      expect(harness.controller.draft.isProductionConfirmed, isTrue);
    },
  );

  testWidgets('keyboard inset leaves editor and in-flow actions scrollable', (
    tester,
  ) async {
    final harness = await _productionHarness();
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
    await pumpCapture(tester, harness.controller, size: const Size(390, 700));

    await tester.ensureVisible(find.byKey(const ValueKey('defer-production')));
    expect(
      find.byKey(const ValueKey('first-production')).hitTestable(),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('defer-production')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<CaptureTestHarness> _productionHarness({bool vocabulary = false}) async {
  final harness = await CaptureTestHarness.create();
  harness.controller.updateContent(vocabulary ? 'record' : 'on the record');
  await harness.controller.discover();
  if (vocabulary) {
    harness.controller.selectSense(harness.controller.lookup!.senses.first);
  } else {
    harness.controller.updateMeaning('officially');
  }
  expect(harness.controller.continueToProduction(), isTrue);
  return harness;
}
