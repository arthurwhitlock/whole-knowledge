import 'package:whole_knowledge/domain/learning/learning_item.dart';

final class CaptureLearningItem {
  const CaptureLearningItem({
    required this.kind,
    required this.content,
    this.meaning,
    this.context,
    this.source,
  });

  final LearningItemKind kind;
  final String content;
  final String? meaning;
  final String? context;
  final String? source;

  CaptureLearningItem normalized() {
    return CaptureLearningItem(
      kind: kind,
      content: content.trim(),
      meaning: _optionalText(meaning),
      context: _optionalText(context),
      source: _optionalText(source),
    );
  }

  static String? _optionalText(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }
}

abstract final class CaptureLearningItemValidator {
  static String? validateContent(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Enter the language you encountered.';
    }
    if (normalized.length > 2000) {
      return 'Keep the captured language under 2,000 characters.';
    }
    return null;
  }

  static String? validateMeaning(String value) {
    return _validateOptional(value, 4000, 'meaning');
  }

  static String? validateContext(String value) {
    return _validateOptional(value, 4000, 'context');
  }

  static String? validateSource(String value) {
    return _validateOptional(value, 1000, 'source');
  }

  static String? _validateOptional(String value, int maximum, String label) {
    if (value.trim().length > maximum) {
      final formattedMaximum = maximum == 1000 ? '1,000' : '4,000';
      return 'Keep the $label under $formattedMaximum characters.';
    }
    return null;
  }
}
