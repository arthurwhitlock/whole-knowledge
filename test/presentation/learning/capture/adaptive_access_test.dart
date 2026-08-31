import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'capture_test_harness.dart';

void main() {
  for (final width in [639.0, 640.0, 759.0, 760.0, 959.0, 960.0]) {
    testWidgets('Capture keeps one document without overflow at width $width', (
      tester,
    ) async {
      final harness = await CaptureTestHarness.create();
      await pumpCapture(tester, harness.controller, size: Size(width, 800));

      expect(
        find.byKey(const ValueKey('capture-document-scroll')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('capture-content')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    '200 percent text scaling wraps actions without horizontal loss',
    (tester) async {
      final harness = await CaptureTestHarness.create();
      await pumpCapture(
        tester,
        harness.controller,
        size: const Size(390, 800),
        textScale: 2,
      );

      expect(find.text('Use Vocabulary discovery'), findsOneWidget);
      expect(find.text('Enter meaning manually'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('ordinary Tab order reaches type and actions with 44px targets', (
    tester,
  ) async {
    final harness = await CaptureTestHarness.create();
    await pumpCapture(tester, harness.controller, size: const Size(390, 800));

    final content = find.byKey(const ValueKey('capture-content'));
    final type = find.byKey(const ValueKey('change-discovery-type'));
    final discover = find.byKey(const ValueKey('discover-language'));
    final manual = find.byKey(const ValueKey('enter-meaning-manually'));
    expect(tester.getSize(type).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(discover).height, greaterThanOrEqualTo(44));
    expect(tester.getSize(manual).height, greaterThanOrEqualTo(44));

    final editor = tester.widget<EditableText>(
      find.descendant(of: content, matching: find.byType(EditableText)),
    );
    editor.focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(FocusManager.instance.primaryFocus, isNot(same(editor.focusNode)));
  });

  testWidgets('disabled animations keep validation stable', (tester) async {
    final harness = await CaptureTestHarness.create();
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpCapture(tester, harness.controller);
    await tester.tap(find.byKey(const ValueKey('discover-language')));
    await tester.pump();

    expect(find.text('Enter the language you encountered.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
