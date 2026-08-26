import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/domain/learning/review_schedule.dart';

void main() {
  test('maps ratings to the V0 review intervals', () {
    expect(
      ReviewSchedule.intervalFor(ReviewRating.again),
      const Duration(minutes: 10),
    );
    expect(
      ReviewSchedule.intervalFor(ReviewRating.hard),
      const Duration(days: 1),
    );
    expect(
      ReviewSchedule.intervalFor(ReviewRating.good),
      const Duration(days: 3),
    );
    expect(
      ReviewSchedule.intervalFor(ReviewRating.easy),
      const Duration(days: 7),
    );
  });

  test('schedules from the review completion instant', () {
    final reviewedAt = DateTime.utc(2026, 8, 25, 12);

    expect(
      ReviewSchedule.nextReviewAt(ReviewRating.good, reviewedAt),
      DateTime.utc(2026, 8, 28, 12),
    );
  });
}
