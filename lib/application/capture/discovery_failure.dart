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

enum DiscoveryFailureField {
  content,
  meaning,
  context,
  source,
  partOfSpeech,
  firstProduction,
}

final class DiscoveryFailureMetadata {
  const DiscoveryFailureMetadata({
    this.field,
    this.httpStatusGroup,
    this.backendCode,
  }) : assert(
         httpStatusGroup == null ||
             (httpStatusGroup >= 1 && httpStatusGroup <= 5),
       );

  final DiscoveryFailureField? field;
  final int? httpStatusGroup;
  final String? backendCode;

  Map<String, Object> toDiagnosticFields() => {
    'field': ?field?.name,
    'httpStatusGroup': ?httpStatusGroup,
    'backendCode': ?backendCode,
  };
}

final class DiscoveryFailure implements Exception {
  const DiscoveryFailure(
    this.code, {
    this.metadata = const DiscoveryFailureMetadata(),
  });

  final DiscoveryFailureCode code;
  final DiscoveryFailureMetadata metadata;

  @override
  String toString() => 'DiscoveryFailure(${code.name})';
}
