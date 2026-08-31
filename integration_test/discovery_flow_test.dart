import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:whole_knowledge/app/app.dart';
import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

import '../test/support/fakes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('vocabulary production re-encounter and targeted Review', (
    tester,
  ) async {
    final dependencies = fakeDependencies();
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    final reviews = dependencies.reviews as FakeReviewRepository;
    await _launch(tester, dependencies: dependencies);

    await _openCapture(tester);
    await _enterAndDiscover(tester, 'record');
    await _tapText(tester, 'A stored account.');
    await _tapKey(tester, 'continue-to-production');
    await tester.enterText(
      find.byKey(const ValueKey('first-production')),
      'I kept a record of the decision.',
    );
    await _tapKey(tester, 'complete-discovery');

    expect(find.text('Discovered'), findsOneWidget);
    expect(learningItems.items, hasLength(1));
    expect(
      learningItems.items.single.firstProduction,
      'I kept a record of the decision.',
    );
    expect(learningItems.items.single.nextReviewAt, isNotNull);

    await _tapKey(tester, 'capture-another');
    await _enterAndDiscover(tester, 'record');
    expect(find.text('Already in your knowledge'), findsOneWidget);
    expect(find.text('A stored account.'), findsNothing);

    await _tapKey(tester, 'test-myself');
    expect(find.byKey(const ValueKey('review-focus')), findsOneWidget);
    await _tapKey(tester, 'reveal-answer');
    await _tapText(tester, 'Continue to production');
    await tester.enterText(
      find.byKey(const ValueKey('production-response')),
      'The archive records every revision.',
    );
    await _tapKey(tester, 'continue-to-rating');
    await _tapKey(tester, 'rating-good');

    expect(find.text('Already in your knowledge'), findsOneWidget);
    expect(reviews.completeCalls, 1);
    expect(learningItems.items.single.reviewCount, 1);
    expect(learningItems.items.single.lastReviewedAt, isNotNull);
  });

  testWidgets('expression defer is immediately due', (tester) async {
    final dependencies = fakeDependencies();
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    await _launch(tester, dependencies: dependencies);

    await _openCapture(tester);
    await _enterAndDiscover(tester, 'on the record');
    await tester.enterText(
      find.byKey(const ValueKey('capture-meaning')),
      'officially and intended to be quoted',
    );
    await tester.pump();
    await _tapKey(tester, 'continue-to-production');
    await _tapKey(tester, 'defer-production');

    expect(find.text('Discovered'), findsOneWidget);
    expect(find.byKey(const ValueKey('discovery-due-now')), findsOneWidget);
    expect(learningItems.items, hasLength(1));
    expect(learningItems.items.single.kind, LearningItemKind.expression);
    expect(learningItems.items.single.firstProduction, isNull);
    expect(
      learningItems.items.single.nextReviewAt,
      DateTime.utc(2026, 8, 30, 19),
    );
  });

  testWidgets('multiple learned senses allow an explicit additional sense', (
    tester,
  ) async {
    final original = [
      learningItem(
        id: 'noun-sense',
        content: 'record',
        meaning: 'An existing noun meaning.',
        partOfSpeech: 'noun',
      ),
      learningItem(
        id: 'adjective-sense',
        content: 'record',
        meaning: 'An existing adjective meaning.',
        partOfSpeech: 'adjective',
      ),
    ];
    final dependencies = fakeDependencies(items: original);
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    await _launch(tester, dependencies: dependencies);

    await _openCapture(tester);
    await _enterAndDiscover(tester, 'record');
    expect(find.text('Already in your knowledge'), findsOneWidget);
    expect(find.byKey(const ValueKey('test-myself')), findsNothing);
    expect(find.text('An existing noun meaning.'), findsNothing);
    expect(find.text('An existing adjective meaning.'), findsNothing);

    await _tapKey(tester, 'learn-another-sense');
    await _tapText(tester, 'To preserve information.');
    await _tapKey(tester, 'continue-to-production');
    await _tapKey(tester, 'defer-production');

    expect(find.text('Discovered'), findsOneWidget);
    expect(learningItems.items, hasLength(3));
    expect(learningItems.items.first.meaning, 'To preserve information.');
    expect(
      learningItems.items.skip(1).map((item) => item.id),
      containsAll(<String>['noun-sense', 'adjective-sense']),
    );
  });
}

Future<void> _launch(
  WidgetTester tester, {
  required AppDependencies dependencies,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 900);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
  await tester.pumpAndSettle();
}

Future<void> _openCapture(WidgetTester tester) async {
  await _tapText(tester, 'Capture', last: true);
}

Future<void> _enterAndDiscover(WidgetTester tester, String content) async {
  await tester.enterText(
    find.byKey(const ValueKey('capture-content')),
    content,
  );
  await _tapKey(tester, 'discover-language');
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _tapText(
  WidgetTester tester,
  String text, {
  bool last = false,
}) async {
  final matches = find.text(text);
  final finder = last ? matches.last : matches.first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
