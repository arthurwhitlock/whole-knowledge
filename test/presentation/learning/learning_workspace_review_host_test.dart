import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/app/app.dart';
import 'package:whole_knowledge/presentation/learning/review_focus_view.dart';

import '../../support/fakes.dart';

void main() {
  testWidgets('Today Review hides the shell and system Back pauses in place', (
    tester,
  ) async {
    await _setViewport(tester);
    await tester.pumpWidget(
      WholeKnowledgeApp(
        dependencies: fakeDependencies(items: [learningItem()]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-review')));
    await tester.pump();

    expect(find.byType(ReviewFocusView), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ReviewFocusView), findsNothing);
    expect(find.byKey(const ValueKey('resume-review')), findsOneWidget);
  });

  testWidgets(
    'Capture targeted Review uses the same host and restores origin',
    (tester) async {
      await _setViewport(tester);
      final item = learningItem(
        content: 'record',
        meaning: 'a stored account',
        nextReviewAt: DateTime.utc(2027),
      );
      await tester.pumpWidget(
        WholeKnowledgeApp(dependencies: fakeDependencies(items: [item])),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capture').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('capture-content')),
        'record',
      );
      await tester.tap(find.byKey(const ValueKey('discover-language')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('test-myself')));
      await tester.pump();

      expect(find.byType(ReviewFocusView), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('pause-review')));
      await tester.pump();
      expect(find.text('Already in your knowledge'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('resume-targeted-review')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('resume-targeted-review')));
      await tester.pump();
      expect(find.byType(ReviewFocusView), findsOneWidget);
    },
  );
}

Future<void> _setViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 800);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
