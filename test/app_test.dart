import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/app.dart';

void main() {
  testWidgets('boots the minimal language OS shell', (tester) async {
    await tester.pumpWidget(const WholeKnowledgeApp());

    expect(find.text('Language OS'), findsOneWidget);
    expect(find.text('Whole Knowledge'), findsOneWidget);
    expect(find.byType(ShadButton), findsOneWidget);
  });

  testWidgets('provides both light and dark themes', (tester) async {
    await tester.pumpWidget(const WholeKnowledgeApp());

    final app = tester.widget<ShadApp>(find.byType(ShadApp));

    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
    expect(app.themeMode, ThemeMode.system);
  });
}
