import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';

abstract final class SupabaseLearningItemMapper {
  static LearningItem fromRow(Map<String, dynamic> row) {
    return LearningItem(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      kind: _learningItemKind(row['kind'] as String),
      content: row['content'] as String,
      partOfSpeech: row['part_of_speech'] as String?,
      meaning: row['meaning'] as String?,
      context: row['context'] as String?,
      source: row['source'] as String?,
      firstProduction: row['first_production'] as String?,
      lastReviewedAt: switch (row['last_reviewed_at']) {
        final String value => DateTime.parse(value).toUtc(),
        _ => null,
      },
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      updatedAt: DateTime.parse(row['updated_at'] as String).toUtc(),
      nextReviewAt: DateTime.parse(row['next_review_at'] as String).toUtc(),
      reviewCount: (row['review_count'] as num).toInt(),
      productionCount: (row['production_count'] as num).toInt(),
      status: _learningItemStatus(row['status'] as String),
    );
  }

  static LearningItemKind _learningItemKind(String value) {
    return switch (value) {
      'expression' => LearningItemKind.expression,
      'vocabulary' => LearningItemKind.vocabulary,
      _ => throw FormatException('Unknown learning item kind: $value'),
    };
  }

  static LearningItemStatus _learningItemStatus(String value) {
    return switch (value) {
      'active' => LearningItemStatus.active,
      'archived' => LearningItemStatus.archived,
      _ => throw FormatException('Unknown learning item status: $value'),
    };
  }
}

abstract final class SupabaseReviewAttemptMapper {
  static ReviewAttempt fromRow(Map<String, dynamic> row) {
    return ReviewAttempt(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      learningItemId: row['learning_item_id'] as String,
      reviewSubmissionId: row['review_submission_id'] as String,
      attemptType: _attemptType(row['attempt_type'] as String),
      rating: _rating(row['rating'] as String?),
      responseText: row['response_text'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
    );
  }

  static ReviewAttemptType _attemptType(String value) {
    return switch (value) {
      'retrieval' => ReviewAttemptType.retrieval,
      'production' => ReviewAttemptType.production,
      _ => throw FormatException('Unknown review attempt type: $value'),
    };
  }

  static ReviewRating? _rating(String? value) {
    return switch (value) {
      null => null,
      'again' => ReviewRating.again,
      'hard' => ReviewRating.hard,
      'good' => ReviewRating.good,
      'easy' => ReviewRating.easy,
      _ => throw FormatException('Unknown review rating: $value'),
    };
  }
}
