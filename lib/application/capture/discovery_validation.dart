import 'package:whole_knowledge/domain/learning/learning_item.dart';

abstract final class DiscoveryValidation {
  static const maximumContentLength = 2000;
  static const maximumMeaningLength = 4000;
  static const maximumContextLength = 4000;
  static const maximumSourceLength = 1000;
  static const maximumPartOfSpeechLength = 80;
  static const maximumProductionLength = 10000;

  static String? validateContent(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Enter the language you encountered.';
    if (normalized.length > maximumContentLength) {
      return 'Keep the captured language under 2,000 characters.';
    }
    return null;
  }

  static String? validateMeaning(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Add the meaning you encountered.';
    if (normalized.length > maximumMeaningLength) {
      return 'Keep the meaning under 4,000 characters.';
    }
    return null;
  }

  static String? validateProduction(String value, {required bool required}) {
    final normalized = value.trim();
    if (required && normalized.isEmpty) {
      return 'Use this language in your own sentence.';
    }
    if (normalized.length > maximumProductionLength) {
      return 'Keep the production under 10,000 characters.';
    }
    return null;
  }

  static String? validateContext(String value) => _validateOptional(
    value,
    maximumContextLength,
    'Keep the context under 4,000 characters.',
  );

  static String? validateSource(String value) => _validateOptional(
    value,
    maximumSourceLength,
    'Keep the source under 1,000 characters.',
  );

  static String? validatePartOfSpeech(String? value) => _validateOptional(
    value ?? '',
    maximumPartOfSpeechLength,
    'Keep the part of speech under 80 characters.',
  );

  static String normalizeContent(String value) => value.trim();

  static String? normalizeOptional(String? value) {
    final normalized = value?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? normalizePartOfSpeech(String? value) {
    final normalized = normalizeOptional(value)?.toLowerCase();
    return switch (normalized) {
      null => null,
      'adj' || 'adjective' => 'adjective',
      'adv' || 'adverb' => 'adverb',
      'n' || 'noun' => 'noun',
      'v' || 'verb' => 'verb',
      'prep' || 'preposition' => 'preposition',
      'pron' || 'pronoun' => 'pronoun',
      _ => normalized,
    };
  }

  static String surfaceMatchKey(String value) {
    var normalized = value.trim().toLowerCase();
    normalized = normalized.replaceAll(
      RegExp(r"[\u2018\u2019\u02bc\uff07]"),
      "'",
    );
    normalized = normalized.replaceAll(
      RegExp(r'[\u2010\u2011\u2012\u2013\u2014\u2212\ufe63\uff0d]'),
      '-',
    );
    normalized = normalized.replaceAll(RegExp(r'\s+'), ' ');
    normalized = normalized.replaceAllMapped(
      RegExp(r"\s*([-'])\s*"),
      (match) => match.group(1)!,
    );
    normalized = normalized.replaceAll(
      RegExp(r'^[\s.,!?;:"“”()\[\]{}]+|[\s.,!?;:"“”()\[\]{}]+$'),
      '',
    );
    return normalized;
  }

  static LearningItemKind suggestKind(String value) {
    final normalized = normalizeContent(value);
    if (normalized.isEmpty) return LearningItemKind.expression;
    final hasWhitespace = RegExp(r'\s').hasMatch(normalized);
    return hasWhitespace
        ? LearningItemKind.expression
        : LearningItemKind.vocabulary;
  }

  static String? _validateOptional(String value, int maximum, String message) {
    return value.trim().length > maximum ? message : null;
  }
}
