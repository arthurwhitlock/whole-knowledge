import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/learning/review_session_controller.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';

import '../../support/fakes.dart';

void main() {
  test(
    'owns recall, reveal, production, rating, and completion transitions',
    () async {
      final learningItems = FakeLearningItemRepository(
        initialItems: [learningItem()],
      );
      final reviews = FakeReviewRepository(learningItems);
      final controller = ReviewSessionController(reviews);

      expect(controller.start(learningItems.items), isTrue);
      expect(controller.stage, ReviewStage.recall);
      controller.reveal();
      controller.enterProduction();
      controller.updateResponse('Je prends mon temps.');
      expect(controller.continueToRating(), isTrue);
      expect(controller.stage, ReviewStage.rating);

      expect(await controller.rate(ReviewRating.good), isNotNull);
      expect(controller.completed, isTrue);
      expect(controller.isReviewing, isFalse);
      expect(controller.responseText, isEmpty);
    },
  );

  test('pause and resume preserve the production response', () {
    final learningItems = FakeLearningItemRepository(
      initialItems: [learningItem()],
    );
    final controller = ReviewSessionController(
      FakeReviewRepository(learningItems),
    );
    controller.start(learningItems.items);
    controller.reveal();
    controller.enterProduction();
    controller.updateResponse('preserved response');

    controller.pause();
    expect(controller.isPaused, isTrue);
    expect(controller.responseText, 'preserved response');

    controller.resume();
    expect(controller.isReviewing, isTrue);
    expect(controller.stage, ReviewStage.production);
    expect(controller.responseText, 'preserved response');
  });

  test('an ambiguous retry reuses immutable submission data', () async {
    final learningItems = FakeLearningItemRepository(
      initialItems: [learningItem()],
    );
    final reviews = FakeReviewRepository(learningItems)..shouldFail = true;
    final controller = ReviewSessionController(reviews);
    controller.start(learningItems.items);
    controller.reveal();
    controller.enterProduction();
    controller.updateResponse('same response');
    controller.continueToRating();

    expect(await controller.rate(ReviewRating.hard), isNull);
    final submissionId = reviews.lastSubmissionId;
    reviews.shouldFail = false;
    expect(await controller.rate(controller.failedRating!), isNotNull);

    expect(reviews.lastSubmissionId, submissionId);
    expect(reviews.lastResponse, 'same response');
    expect(reviews.lastRating, ReviewRating.hard);
  });

  test('a paused response cannot be replaced by a new launch', () {
    final learningItems = FakeLearningItemRepository();
    final controller = ReviewSessionController(
      FakeReviewRepository(learningItems),
    );
    final first = learningItem(id: 'first', content: 'first item');
    final replacement = learningItem(id: 'second', content: 'second item');

    expect(controller.start([first]), isTrue);
    controller.reveal();
    controller.enterProduction();
    controller.updateResponse('preserved response');
    controller.pause();

    expect(controller.start([replacement]), isFalse);
    expect(controller.queue.single.id, 'first');
    expect(controller.responseText, 'preserved response');
    expect(controller.isPaused, isTrue);
  });
}
