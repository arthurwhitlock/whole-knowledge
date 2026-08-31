import 'package:whole_knowledge/application/capture/discovery_failure.dart';

enum DiscoveryDiagnosticOperation {
  draftRead,
  draftWrite,
  libraryCheck,
  lexicalLookup,
  completeDiscovery,
}

enum DiscoveryDiagnosticPhase {
  restoring,
  entry,
  checking,
  vocabularyMeaning,
  expressionMeaning,
  reEncounter,
  production,
  saving,
  reconciling,
  discovered,
}

final class DiscoveryDiagnosticEvent {
  const DiscoveryDiagnosticEvent({
    required this.operation,
    required this.phase,
    this.failureCode,
    this.failureMetadata = const DiscoveryFailureMetadata(),
    this.duration,
    this.retryCount,
    this.requestGeneration,
    this.itemId,
    this.submissionId,
    this.reconciliationSucceeded,
  });

  final DiscoveryDiagnosticOperation operation;
  final DiscoveryDiagnosticPhase phase;
  final DiscoveryFailureCode? failureCode;
  final DiscoveryFailureMetadata failureMetadata;
  final Duration? duration;
  final int? retryCount;
  final int? requestGeneration;
  final String? itemId;
  final String? submissionId;
  final bool? reconciliationSucceeded;

  Map<String, Object> toMetadata() => {
    'operation': operation.name,
    'phase': phase.name,
    'failureCode': ?failureCode?.name,
    ...failureMetadata.toDiagnosticFields(),
    'durationMs': ?duration?.inMilliseconds,
    'retryCount': ?retryCount,
    'requestGeneration': ?requestGeneration,
    'itemId': ?itemId,
    'submissionId': ?submissionId,
    'reconciliationSucceeded': ?reconciliationSucceeded,
  };
}

abstract interface class DiscoveryDiagnostics {
  void record(DiscoveryDiagnosticEvent event);
}

final class NoopDiscoveryDiagnostics implements DiscoveryDiagnostics {
  const NoopDiscoveryDiagnostics();

  @override
  void record(DiscoveryDiagnosticEvent event) {}
}
