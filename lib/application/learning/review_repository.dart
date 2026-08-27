import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';

abstract interface class ReviewRepository {
  Future<LearningItem> completeReview({
    required LearningItem item,
    required String submissionId,
    required String responseText,
    required ReviewRating rating,
  });

  Future<List<ReviewAttempt>> listAttempts({
    required String learningItemId,
    required int offset,
    required int limit,
  });
}
