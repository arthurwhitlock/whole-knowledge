import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/lexical_provider.dart';

import '../../../support/fakes.dart';
import 'capture_test_harness.dart';

void main() {
  testWidgets('blank Discover keeps the adjacent Language error focused', (
    tester,
  ) async {
    final harness = await CaptureTestHarness.create();
    await pumpCapture(tester, harness.controller);

    await tester.tap(find.byKey(const ValueKey('discover-language')));
    await tester.pump();

    final field = find.byKey(const ValueKey('capture-content'));
    final editor = tester.widget<EditableText>(
      find.descendant(of: field, matching: find.byType(EditableText)),
    );
    expect(find.text('Enter the language you encountered.'), findsOneWidget);
    expect(editor.focusNode.hasFocus, isTrue);
  });

  testWidgets('type suggestion, reversal, Enter, and Discover share order', (
    tester,
  ) async {
    final harness = await CaptureTestHarness.create();
    await pumpCapture(tester, harness.controller);
    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      'on the record',
    );
    await tester.pump();

    expect(find.text('Expression suggested'), findsOneWidget);
    expect(find.text('Use Vocabulary discovery'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('change-discovery-type')));
    await tester.pump();
    expect(find.text('Vocabulary'), findsOneWidget);
    expect(find.text('Use Expression'), findsOneWidget);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(harness.lexical.lookupCalls, 1);
    expect(find.text('Choose the meaning you encountered'), findsOneWidget);
  });

  testWidgets('Library and lexical progress resolve independently', (
    tester,
  ) async {
    final harness = await CaptureTestHarness.create();
    final libraryGate = Completer<void>();
    final lexicalGate = Completer<LexicalLookup>();
    harness.items.matchGate = libraryGate;
    harness.lexical.lookupGate = lexicalGate;
    await pumpCapture(tester, harness.controller);
    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      'record',
    );
    await tester.tap(find.byKey(const ValueKey('discover-language')));
    await tester.pump();

    expect(find.byKey(const ValueKey('library-pending')), findsOneWidget);
    expect(find.byKey(const ValueKey('lexical-pending')), findsOneWidget);

    lexicalGate.complete(harness.lexical.result);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('A stored account.'), findsOneWidget);
    expect(find.byKey(const ValueKey('library-pending')), findsOneWidget);

    libraryGate.complete();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-clear')), findsOneWidget);
  });

  testWidgets('late Library match interrupts without losing authored meaning', (
    tester,
  ) async {
    final existing = learningItem(content: 'record', meaning: 'saved answer');
    final harness = await CaptureTestHarness.create(initialItems: [existing]);
    final libraryGate = Completer<void>();
    harness.items.matchGate = libraryGate;
    await pumpCapture(tester, harness.controller);
    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      'record',
    );
    await tester.tap(find.byKey(const ValueKey('discover-language')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('A stored account.'));
    await tester.pump();

    libraryGate.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Already in your knowledge'), findsOneWidget);
    expect(harness.controller.draft.meaning, 'A stored account.');

    await tester.tap(find.byKey(const ValueKey('learn-another-sense')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('A stored account.'), findsWidgets);
  });
}
