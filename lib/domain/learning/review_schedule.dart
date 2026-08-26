import 'package:whole_knowledge/domain/learning/review_attempt.dart';

abstract final class ReviewSchedule {
  static Duration intervalFor(ReviewRating rating) {
    return switch (rating) {
      ReviewRating.again => const Duration(minutes: 10),
      ReviewRating.hard => const Duration(days: 1),
      ReviewRating.good => const Duration(days: 3),
      ReviewRating.easy => const Duration(days: 7),
    };
  }

  static DateTime nextReviewAt(ReviewRating rating, DateTime reviewedAt) {
    return reviewedAt.add(intervalFor(rating));
  }
}
