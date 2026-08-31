import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/capture/capture_session_controller.dart';
import 'package:whole_knowledge/application/capture/discovery_diagnostics.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';

import '../../support/fakes.dart';

void main() {
  test('diagnostic serialization exposes only the approved metadata shape', () {
    const event = DiscoveryDiagnosticEvent(
      operation: DiscoveryDiagnosticOperation.lexicalLookup,
      phase: DiscoveryDiagnosticPhase.vocabularyMeaning,
      failureCode: DiscoveryFailureCode.lexicalServiceUnavailable,
      failureMetadata: DiscoveryFailureMetadata(httpStatusGroup: 5),
      duration: Duration(milliseconds: 240),
      retryCount: 1,
      requestGeneration: 3,
      itemId: 'opaque-item-id',
      submissionId: 'opaque-submission-id',
      reconciliationSucceeded: false,
    );

    expect(event.toMetadata(), {
      'operation': 'lexicalLookup',
      'phase': 'vocabularyMeaning',
      'failureCode': 'lexicalServiceUnavailable',
      'httpStatusGroup': 5,
      'durationMs': 240,
      'retryCount': 1,
      'requestGeneration': 3,
      'itemId': 'opaque-item-id',
      'submissionId': 'opaque-submission-id',
      'reconciliationSucceeded': false,
    });
    expect(
      event.toMetadata().keys,
      isNot(
        containsAll(<String>[
          'content',
          'meaning',
          'production',
          'context',
          'source',
          'token',
        ]),
      ),
    );
  });

  test(
    'controller reports a typed lexical failure without learner text',
    () async {
      final diagnostics = _RecordingDiscoveryDiagnostics();
      final lexical = FakeLexicalProvider()
        ..error = const DiscoveryFailure(
          DiscoveryFailureCode.lexicalRateLimited,
        );
      final controller = CaptureSessionController(
        FakeCaptureDraftRepository(),
        lexical,
        FakeLearningItemRepository(),
        Duration.zero,
        diagnostics,
      );
      addTearDown(controller.dispose);
      await controller.restore();
      controller.updateContent('privatelearnerlanguage');

      await controller.discover();

      expect(diagnostics.events, hasLength(1));
      final metadata = diagnostics.events.single.toMetadata();
      expect(metadata['operation'], 'lexicalLookup');
      expect(metadata['failureCode'], 'lexicalRateLimited');
      expect(metadata.values, isNot(contains('privatelearnerlanguage')));
    },
  );
}

final class _RecordingDiscoveryDiagnostics implements DiscoveryDiagnostics {
  final events = <DiscoveryDiagnosticEvent>[];

  @override
  void record(DiscoveryDiagnosticEvent event) => events.add(event);
}
