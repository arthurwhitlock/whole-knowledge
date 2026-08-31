import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/lexical_provider.dart';

import 'capture_test_harness.dart';

void main() {
  testWidgets('all POS headings render with two senses before expansion', (
    tester,
  ) async {
    final harness = await _vocabularyHarness();
    await pumpCapture(tester, harness.controller, size: const Size(900, 1000));

    expect(find.text('NOUN'), findsOneWidget);
    expect(find.text('VERB'), findsOneWidget);
    expect(find.text('noun one'), findsOneWidget);
    expect(find.text('noun two'), findsOneWidget);
    expect(find.text('noun three'), findsNothing);
    expect(find.text('verb one'), findsOneWidget);
    expect(find.text('verb two'), findsOneWidget);
    expect(find.text('verb three'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('expand-senses-0')));
    await tester.pump();
    expect(find.text('noun three'), findsOneWidget);
    expect(find.text('verb three'), findsNothing);
    expect(find.byKey(const ValueKey('manual-meaning')), findsOneWidget);
  });

  testWidgets(
    'sense selection is semantic and selected meaning edits in place',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final harness = await _vocabularyHarness();
      await pumpCapture(tester, harness.controller);

      await tester.tap(find.text('noun one'));
      await tester.pump();
      final selected = tester.getSemantics(
        find.bySemanticsLabel('noun one').first,
      );
      expect(selected.flagsCollection.isSelected, Tristate.isTrue);
      expect(
        find.byKey(const ValueKey('selected-meaning-summary')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('edit-selected-meaning')),
      );
      await tester.tap(find.byKey(const ValueKey('edit-selected-meaning')));
      await tester.pump();
      final editor = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('capture-meaning')),
          matching: find.byType(EditableText),
        ),
      );
      expect(editor.focusNode.hasFocus, isTrue);
      semantics.dispose();
    },
  );

  testWidgets('edited provider meaning requires inline Keep or Replace', (
    tester,
  ) async {
    final harness = await _vocabularyHarness();
    await pumpCapture(tester, harness.controller);
    await tester.ensureVisible(find.text('noun one'));
    await tester.tap(find.text('noun one'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('edit-selected-meaning')),
    );
    await tester.tap(find.byKey(const ValueKey('edit-selected-meaning')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('capture-meaning')),
      'my edited meaning',
    );
    await tester.pump();
    await tester.ensureVisible(find.text('noun two'));
    await tester.tap(find.text('noun two'));
    await tester.pump();

    expect(
      find.text('Replace your edited meaning with this sense?'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('keep-edited-meaning')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('replace-edited-meaning')),
      findsOneWidget,
    );
    expect(harness.controller.draft.meaning, 'my edited meaning');

    await tester.tap(find.byKey(const ValueKey('replace-edited-meaning')));
    await tester.pump();
    expect(harness.controller.draft.meaning, 'noun two');
  });

  testWidgets('manual buffer returns and details appear only after meaning', (
    tester,
  ) async {
    final harness = await _vocabularyHarness();
    await pumpCapture(tester, harness.controller);
    expect(
      find.byKey(const ValueKey('encounter-details-toggle')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('manual-meaning')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('capture-meaning')),
      'my manual meaning',
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('encounter-details-toggle')),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('noun one'));
    await tester.tap(find.text('noun one'));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('manual-meaning')));
    await tester.tap(find.byKey(const ValueKey('manual-meaning')));
    await tester.pump();
    expect(harness.controller.draft.meaning, 'my manual meaning');

    await tester.ensureVisible(
      find.byKey(const ValueKey('encounter-details-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('encounter-details-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey('capture-context')), findsOneWidget);
    expect(find.byKey(const ValueKey('capture-source')), findsOneWidget);
  });

  testWidgets('oversized encounter source remains editable with clear error', (
    tester,
  ) async {
    final harness = await _vocabularyHarness();
    await pumpCapture(tester, harness.controller, size: const Size(900, 1000));
    await tester.tap(find.text('noun one'));
    await tester.pump();
    await tester.ensureVisible(
      find.byKey(const ValueKey('encounter-details-toggle')),
    );
    await tester.tap(find.byKey(const ValueKey('encounter-details-toggle')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('capture-source')),
      's' * 1001,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('continue-to-production')),
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-production')));
    await tester.pump();

    expect(
      find.text('Keep the source under 1,000 characters.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('capture-source')), findsOneWidget);
    expect(harness.items.discoverySubmissions, isEmpty);
  });
}

Future<CaptureTestHarness> _vocabularyHarness() async {
  final harness = await CaptureTestHarness.create();
  harness.lexical.result = const LexicalLookup(
    term: 'record',
    senses: [
      LexicalSense(partOfSpeech: 'noun', definition: 'noun one'),
      LexicalSense(partOfSpeech: 'noun', definition: 'noun two'),
      LexicalSense(
        partOfSpeech: 'noun',
        definition: 'noun three',
        example: 'A readable provider example.',
      ),
      LexicalSense(partOfSpeech: 'verb', definition: 'verb one'),
      LexicalSense(partOfSpeech: 'verb', definition: 'verb two'),
      LexicalSense(partOfSpeech: 'verb', definition: 'verb three'),
    ],
  );
  harness.controller.updateContent('record');
  await harness.controller.discover();
  return harness;
}
