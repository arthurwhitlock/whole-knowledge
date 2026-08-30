import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/app/app.dart';

import 'support/fakes.dart';

void main() {
  // Regression: ISSUE-001 — empty Capture validation stayed offscreen.
  // Found by /qa on 2026-08-28.
  // Report: .gstack/qa-reports/qa-report-whole-knowledge-linux-2026-08-28.md
  testWidgets('empty save reveals and focuses the required Language field', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1200, 720);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      WholeKnowledgeApp(dependencies: fakeDependencies()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();

    final discover = find.byKey(const ValueKey('discover-language'));
    await tester.tap(discover);
    await tester.pumpAndSettle();

    final content = find.byKey(const ValueKey('capture-content'));
    final editor = tester.widget<EditableText>(
      find.descendant(of: content, matching: find.byType(EditableText)),
    );
    expect(find.text('Enter the language you encountered.'), findsOneWidget);
    expect(editor.focusNode.hasFocus, isTrue);
    expect(content.hitTestable(), findsOneWidget);
  });
}
