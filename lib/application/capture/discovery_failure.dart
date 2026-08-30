enum DiscoveryFailureCode {
  draftReadFailure,
  draftFormatInvalid,
  draftVersionUnsupported,
  draftWriteFailure,
  libraryCheckUnavailable,
  sessionUnavailable,
  lexicalEntryNotFound,
  lexicalRateLimited,
  lexicalTimedOut,
  lexicalServiceUnavailable,
  lexicalPayloadInvalid,
  lexicalResponseTooLarge,
  discoveryValidationRejected,
  discoverySubmissionConflict,
  discoveryServiceUnavailable,
  discoveryOutcomeUnknown,
  reviewItemUnavailable,
}

final class DiscoveryFailure implements Exception {
  const DiscoveryFailure(this.code, {this.metadata = const {}});

  final DiscoveryFailureCode code;
  final Map<String, Object?> metadata;

  @override
  String toString() => 'DiscoveryFailure(${code.name})';
}
