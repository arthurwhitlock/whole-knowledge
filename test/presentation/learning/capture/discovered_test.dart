import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'capture_test_harness.dart';

void main() {
  testWidgets('persisted schedule renders relative visual and full semantics', (
    tester,
  ) async {
    final harness = await _discoveredHarness();
    final now = DateTime.utc(2026, 8, 30, 12);
    final semantics = tester.ensureSemantics();
    await pumpCapture(tester, harness.controller, clock: () => now);

    expect(find.text('Discovered'), findsOneWidget);
    expect(find.text('“I said it on the record.”'), findsOneWidget);
    expect(find.textContaining('First review tomorrow'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('First review.*August 31, 2026')),
      findsOneWidget,
    );
    semantics.dispose();
  });

  testWidgets('deferred production omits quotation and says due now', (
    tester,
  ) async {
    final harness = await _discoveredHarness(defer: true);
    await pumpCapture(
      tester,
      harness.controller,
      clock: () => DateTime.utc(2026, 8, 30, 12),
    );

    expect(find.byKey(const ValueKey('discovery-due-now')), findsOneWidget);
    expect(find.text('Ready to practice now'), findsOneWidget);
    expect(find.textContaining('“'), findsNothing);
  });

  testWidgets('midnight and resume refresh relative copy without navigation', (
    tester,
  ) async {
    final harness = await _discoveredHarness();
    var now = DateTime(2026, 8, 30, 23, 59);
    var done = 0;
    await pumpCapture(
      tester,
      harness.controller,
      clock: () => now,
      onCaptured: () => done += 1,
    );
    expect(find.textContaining('First review tomorrow'), findsOneWidget);

    now = DateTime(2026, 8, 31);
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(find.textContaining('First review later today'), findsOneWidget);
    expect(done, 0);

    now = DateTime(2026, 9, 1, 8);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(find.textContaining('First review yesterday'), findsOneWidget);
    expect(done, 0);
  });

  testWidgets('Done precedes Capture another and actions stack when narrow', (
    tester,
  ) async {
    final harness = await _discoveredHarness();
    var done = 0;
    await pumpCapture(
      tester,
      harness.controller,
      size: const Size(390, 760),
      onCaptured: () => done += 1,
    );

    final doneButton = find.byKey(const ValueKey('discovery-done'));
    final another = find.byKey(const ValueKey('capture-another'));
    expect(
      tester.getTopLeft(doneButton).dy,
      lessThan(tester.getTopLeft(another).dy),
    );
    await tester.tap(doneButton);
    expect(done, 1);
  });
}

Future<CaptureTestHarness> _discoveredHarness({bool defer = false}) async {
  final harness = await CaptureTestHarness.create();
  harness.controller.updateContent('on the record');
  await harness.controller.discover();
  harness.controller.updateMeaning('officially');
  expect(harness.controller.continueToProduction(), isTrue);
  if (!defer) {
    harness.controller.updateProduction('I said it on the record.');
  }
  final item = await harness.controller.completeDiscovery(
    deferProduction: defer,
  );
  expect(item, isNotNull);
  return harness;
}
