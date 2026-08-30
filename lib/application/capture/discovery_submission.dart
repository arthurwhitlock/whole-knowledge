import 'package:whole_knowledge/application/capture/discovery_validation.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

final class DiscoverySubmission {
  const DiscoverySubmission({
    required this.submissionId,
    required this.kind,
    required this.content,
    required this.meaning,
    required this.allowExistingSurface,
    this.partOfSpeech,
    this.context,
    this.source,
    this.firstProduction,
  });

  factory DiscoverySubmission.fromJson(Map<String, Object?> json) {
    return DiscoverySubmission(
      submissionId: json['submissionId']! as String,
      kind: LearningItemKind.values.byName(json['kind']! as String),
      content: json['content']! as String,
      partOfSpeech: json['partOfSpeech'] as String?,
      meaning: json['meaning']! as String,
      context: json['context'] as String?,
      source: json['source'] as String?,
      firstProduction: json['firstProduction'] as String?,
      allowExistingSurface: json['allowExistingSurface']! as bool,
    );
  }

  final String submissionId;
  final LearningItemKind kind;
  final String content;
  final String? partOfSpeech;
  final String meaning;
  final String? context;
  final String? source;
  final String? firstProduction;
  final bool allowExistingSurface;

  DiscoverySubmission normalized() => DiscoverySubmission(
    submissionId: submissionId,
    kind: kind,
    content: DiscoveryValidation.normalizeContent(content),
    partOfSpeech: DiscoveryValidation.normalizePartOfSpeech(partOfSpeech),
    meaning: meaning.trim(),
    context: DiscoveryValidation.normalizeOptional(context),
    source: DiscoveryValidation.normalizeOptional(source),
    firstProduction: DiscoveryValidation.normalizeOptional(firstProduction),
    allowExistingSurface: allowExistingSurface,
  );

  bool hasSamePayload(DiscoverySubmission other) {
    final left = normalized();
    final right = other.normalized();
    return left.submissionId == right.submissionId &&
        left.kind == right.kind &&
        left.content == right.content &&
        left.partOfSpeech == right.partOfSpeech &&
        left.meaning == right.meaning &&
        left.context == right.context &&
        left.source == right.source &&
        left.firstProduction == right.firstProduction &&
        left.allowExistingSurface == right.allowExistingSurface;
  }

  Map<String, Object?> toJson() => {
    'submissionId': submissionId,
    'kind': kind.name,
    'content': content,
    'partOfSpeech': partOfSpeech,
    'meaning': meaning,
    'context': context,
    'source': source,
    'firstProduction': firstProduction,
    'allowExistingSurface': allowExistingSurface,
  };
}

sealed class DiscoveryCompletion {
  const DiscoveryCompletion(this.item);

  final LearningItem item;
}

final class DiscoveryCreated extends DiscoveryCompletion {
  const DiscoveryCreated(super.item);
}

final class DiscoveryReplayed extends DiscoveryCompletion {
  const DiscoveryReplayed(super.item);
}

final class DiscoveryExistingSurface extends DiscoveryCompletion {
  const DiscoveryExistingSurface(super.item);
}
