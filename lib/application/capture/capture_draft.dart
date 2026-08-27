import 'package:whole_knowledge/domain/learning/learning_item.dart';

final class CaptureDraft {
  const CaptureDraft({
    this.kind = LearningItemKind.expression,
    this.content = '',
    this.partOfSpeech,
    this.meaning = '',
    this.context = '',
    this.source = '',
  });

  factory CaptureDraft.fromJson(Map<String, Object?> json) {
    final kindName = json['kind'] as String?;
    return CaptureDraft(
      kind: kindName == LearningItemKind.vocabulary.name
          ? LearningItemKind.vocabulary
          : LearningItemKind.expression,
      content: json['content'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String?,
      meaning: json['meaning'] as String? ?? '',
      context: json['context'] as String? ?? '',
      source: json['source'] as String? ?? '',
    );
  }

  final LearningItemKind kind;
  final String content;
  final String? partOfSpeech;
  final String meaning;
  final String context;
  final String source;

  bool get isMeaningful =>
      content.trim().isNotEmpty ||
      meaning.trim().isNotEmpty ||
      context.trim().isNotEmpty ||
      source.trim().isNotEmpty ||
      (partOfSpeech?.trim().isNotEmpty ?? false);

  CaptureDraft copyWith({
    LearningItemKind? kind,
    String? content,
    String? partOfSpeech,
    bool clearPartOfSpeech = false,
    String? meaning,
    String? context,
    String? source,
  }) {
    return CaptureDraft(
      kind: kind ?? this.kind,
      content: content ?? this.content,
      partOfSpeech: clearPartOfSpeech
          ? null
          : partOfSpeech ?? this.partOfSpeech,
      meaning: meaning ?? this.meaning,
      context: context ?? this.context,
      source: source ?? this.source,
    );
  }

  Map<String, Object?> toJson() => {
    'version': 1,
    'kind': kind.name,
    'content': content,
    'partOfSpeech': partOfSpeech,
    'meaning': meaning,
    'context': context,
    'source': source,
  };
}

abstract interface class CaptureDraftRepository {
  Future<CaptureDraft?> read();

  Future<void> write(CaptureDraft draft);

  Future<void> clear();
}
