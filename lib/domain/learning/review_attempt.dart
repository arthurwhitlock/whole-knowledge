enum ReviewAttemptType { retrieval, production }

enum ReviewRating { again, hard, good, easy }

final class ReviewAttempt {
  const ReviewAttempt({
    required this.id,
    required this.userId,
    required this.learningItemId,
    required this.reviewSubmissionId,
    required this.attemptType,
    required this.createdAt,
    this.rating,
    this.responseText,
  });

  final String id;
  final String userId;
  final String learningItemId;
  final String reviewSubmissionId;
  final ReviewAttemptType attemptType;
  final ReviewRating? rating;
  final String? responseText;
  final DateTime createdAt;
}
