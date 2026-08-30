import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

enum DiscoverySubmissionCheckpointStatus { prepared, attempted }

final class DiscoverySubmissionCheckpoint {
  const DiscoverySubmissionCheckpoint({
    required this.status,
    required this.submission,
  });

  factory DiscoverySubmissionCheckpoint.fromJson(Map<String, Object?> json) {
    return DiscoverySubmissionCheckpoint(
      status: DiscoverySubmissionCheckpointStatus.values.byName(
        json['status']! as String,
      ),
      submission: DiscoverySubmission.fromJson(
        Map<String, Object?>.from(json['submission']! as Map),
      ),
    );
  }

  final DiscoverySubmissionCheckpointStatus status;
  final DiscoverySubmission submission;

  DiscoverySubmissionCheckpoint copyWith({
    DiscoverySubmissionCheckpointStatus? status,
  }) => DiscoverySubmissionCheckpoint(
    status: status ?? this.status,
    submission: submission,
  );

  Map<String, Object?> toJson() => {
    'status': status.name,
    'submission': submission.toJson(),
  };
}

final class CaptureDraft {
  const CaptureDraft({
    this.draftRevision = 0,
    this.kind = LearningItemKind.expression,
    this.content = '',
    this.partOfSpeech,
    this.meaning = '',
    this.manualMeaningBuffer = '',
    this.context = '',
    this.source = '',
    this.production = '',
    this.meaningRevision = 0,
    this.meaningConfirmedRevision,
    this.productionConfirmedMeaningRevision,
    this.submissionCheckpoint,
  });

  factory CaptureDraft.fromJson(Map<String, Object?> json) {
    final version = json['version'];
    return switch (version) {
      1 => CaptureDraft._fromV1(json),
      2 => CaptureDraft._fromV2(json),
      _ => throw const FormatException('Unsupported Capture draft version.'),
    };
  }

  factory CaptureDraft._fromV1(Map<String, Object?> json) {
    final meaning = json['meaning'] as String? ?? '';
    return CaptureDraft(
      kind: _kindFromJson(json['kind']),
      content: json['content'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String?,
      meaning: meaning,
      manualMeaningBuffer: meaning,
      context: json['context'] as String? ?? '',
      source: json['source'] as String? ?? '',
      meaningRevision: meaning.trim().isEmpty ? 0 : 1,
    );
  }

  factory CaptureDraft._fromV2(Map<String, Object?> json) {
    final checkpointJson = json['submissionCheckpoint'];
    return CaptureDraft(
      draftRevision: (json['draftRevision'] as num?)?.toInt() ?? 0,
      kind: _kindFromJson(json['kind']),
      content: json['content'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String?,
      meaning: json['meaning'] as String? ?? '',
      manualMeaningBuffer: json['manualMeaningBuffer'] as String? ?? '',
      context: json['context'] as String? ?? '',
      source: json['source'] as String? ?? '',
      production: json['production'] as String? ?? '',
      meaningRevision: (json['meaningRevision'] as num?)?.toInt() ?? 0,
      meaningConfirmedRevision: (json['meaningConfirmedRevision'] as num?)
          ?.toInt(),
      productionConfirmedMeaningRevision:
          (json['productionConfirmedMeaningRevision'] as num?)?.toInt(),
      submissionCheckpoint: checkpointJson is Map
          ? DiscoverySubmissionCheckpoint.fromJson(
              Map<String, Object?>.from(checkpointJson),
            )
          : null,
    );
  }

  final int draftRevision;
  final LearningItemKind kind;
  final String content;
  final String? partOfSpeech;
  final String meaning;
  final String manualMeaningBuffer;
  final String context;
  final String source;
  final String production;
  final int meaningRevision;
  final int? meaningConfirmedRevision;
  final int? productionConfirmedMeaningRevision;
  final DiscoverySubmissionCheckpoint? submissionCheckpoint;

  bool get isMeaningful =>
      content.trim().isNotEmpty ||
      meaning.trim().isNotEmpty ||
      manualMeaningBuffer.trim().isNotEmpty ||
      context.trim().isNotEmpty ||
      source.trim().isNotEmpty ||
      production.trim().isNotEmpty ||
      (partOfSpeech?.trim().isNotEmpty ?? false) ||
      submissionCheckpoint != null;

  bool get isMeaningConfirmed =>
      meaning.trim().isNotEmpty && meaningConfirmedRevision == meaningRevision;

  bool get isProductionConfirmed =>
      production.trim().isNotEmpty &&
      productionConfirmedMeaningRevision == meaningRevision;

  CaptureDraft copyWith({
    int? draftRevision,
    LearningItemKind? kind,
    String? content,
    String? partOfSpeech,
    bool clearPartOfSpeech = false,
    String? meaning,
    String? manualMeaningBuffer,
    String? context,
    String? source,
    String? production,
    int? meaningRevision,
    int? meaningConfirmedRevision,
    bool clearMeaningConfirmedRevision = false,
    int? productionConfirmedMeaningRevision,
    bool clearProductionConfirmedMeaningRevision = false,
    DiscoverySubmissionCheckpoint? submissionCheckpoint,
    bool clearSubmissionCheckpoint = false,
  }) {
    return CaptureDraft(
      draftRevision: draftRevision ?? this.draftRevision,
      kind: kind ?? this.kind,
      content: content ?? this.content,
      partOfSpeech: clearPartOfSpeech
          ? null
          : partOfSpeech ?? this.partOfSpeech,
      meaning: meaning ?? this.meaning,
      manualMeaningBuffer: manualMeaningBuffer ?? this.manualMeaningBuffer,
      context: context ?? this.context,
      source: source ?? this.source,
      production: production ?? this.production,
      meaningRevision: meaningRevision ?? this.meaningRevision,
      meaningConfirmedRevision: clearMeaningConfirmedRevision
          ? null
          : meaningConfirmedRevision ?? this.meaningConfirmedRevision,
      productionConfirmedMeaningRevision:
          clearProductionConfirmedMeaningRevision
          ? null
          : productionConfirmedMeaningRevision ??
                this.productionConfirmedMeaningRevision,
      submissionCheckpoint: clearSubmissionCheckpoint
          ? null
          : submissionCheckpoint ?? this.submissionCheckpoint,
    );
  }

  CaptureDraft nextRevision() => copyWith(draftRevision: draftRevision + 1);

  Map<String, Object?> toJson() => {
    'version': 2,
    'draftRevision': draftRevision,
    'kind': kind.name,
    'content': content,
    'partOfSpeech': partOfSpeech,
    'meaning': meaning,
    'manualMeaningBuffer': manualMeaningBuffer,
    'context': context,
    'source': source,
    'production': production,
    'meaningRevision': meaningRevision,
    'meaningConfirmedRevision': meaningConfirmedRevision,
    'productionConfirmedMeaningRevision': productionConfirmedMeaningRevision,
    'submissionCheckpoint': submissionCheckpoint?.toJson(),
  };

  static LearningItemKind _kindFromJson(Object? value) {
    return value == LearningItemKind.vocabulary.name
        ? LearningItemKind.vocabulary
        : LearningItemKind.expression;
  }
}

abstract interface class CaptureDraftRepository {
  Future<CaptureDraft?> read();

  Future<void> write(CaptureDraft draft);

  Future<void> clear();
}
