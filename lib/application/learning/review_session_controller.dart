import 'package:whole_knowledge/application/learning/review_repository.dart';
import 'package:whole_knowledge/application/learning/review_submission_id.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';

enum ReviewStage { recall, revealed, production, rating }

typedef ReviewSessionListener = void Function();

final class ReviewSessionController {
  ReviewSessionController(this._reviews);

  final ReviewRepository _reviews;
  final Set<ReviewSessionListener> _listeners = {};
  List<LearningItem> queue = [];
  ReviewStage stage = ReviewStage.recall;
  bool isReviewing = false;
  bool isPaused = false;
  bool completed = false;
  bool isSaving = false;
  String responseText = '';
  String? error;
  ReviewRating? failedRating;
  String _submissionId = ReviewSubmissionId.generate();
  int reviewedInSession = 0;
  int reviewTotal = 0;

  void addListener(ReviewSessionListener listener) => _listeners.add(listener);
  void removeListener(ReviewSessionListener listener) =>
      _listeners.remove(listener);

  void updateDueItems(List<LearningItem> dueItems) {
    if (isReviewing || isPaused) return;
    queue = List.of(dueItems);
    if (queue.isNotEmpty) completed = false;
    _notify();
  }

  bool start(List<LearningItem> dueItems) {
    if (isReviewing || isPaused) return false;
    queue = List.of(dueItems);
    isReviewing = queue.isNotEmpty;
    isPaused = false;
    completed = false;
    stage = ReviewStage.recall;
    error = null;
    failedRating = null;
    responseText = '';
    reviewedInSession = 0;
    reviewTotal = queue.length;
    _submissionId = ReviewSubmissionId.generate();
    _notify();
    return isReviewing;
  }

  void resume() {
    if (queue.isEmpty) return;
    isReviewing = true;
    isPaused = false;
    _notify();
  }

  void pause() {
    if (isSaving || !isReviewing) return;
    isReviewing = false;
    isPaused = true;
    _notify();
  }

  void reveal() {
    if (stage != ReviewStage.recall) return;
    stage = ReviewStage.revealed;
    _notify();
  }

  void enterProduction() {
    if (stage != ReviewStage.revealed) return;
    stage = ReviewStage.production;
    error = null;
    failedRating = null;
    _notify();
  }

  void updateResponse(String value) {
    responseText = value;
    if (error != null) error = null;
    _notify();
  }

  bool continueToRating() {
    final response = responseText.trim();
    if (response.isEmpty) {
      error = 'Write a response before self-rating.';
      _notify();
      return false;
    }
    if (response.length > 10000) {
      error = 'Keep the production response under 10,000 characters.';
      _notify();
      return false;
    }
    responseText = response;
    stage = ReviewStage.rating;
    error = null;
    _notify();
    return true;
  }

  Future<LearningItem?> rate(ReviewRating rating) async {
    if (isSaving || queue.isEmpty || stage != ReviewStage.rating) return null;
    isSaving = true;
    error = null;
    _notify();
    try {
      final updatedItem = await _reviews.completeReview(
        item: queue.first,
        submissionId: _submissionId,
        responseText: responseText,
        rating: rating,
      );
      queue.removeAt(0);
      reviewedInSession += 1;
      responseText = '';
      _submissionId = ReviewSubmissionId.generate();
      isSaving = false;
      failedRating = null;
      stage = ReviewStage.recall;
      if (queue.isEmpty) {
        isReviewing = false;
        completed = true;
      }
      _notify();
      return updatedItem;
    } on Object {
      isSaving = false;
      stage = ReviewStage.rating;
      failedRating = rating;
      error = 'Could not confirm this review. Retry safely with the same response, or discard it and reload the queue.';
      _notify();
      return null;
    }
  }

  void discard() {
    isReviewing = false;
    isPaused = false;
    completed = false;
    stage = ReviewStage.recall;
    error = null;
    failedRating = null;
    responseText = '';
    queue = [];
    _notify();
  }

  void dispose() => _listeners.clear();

  void _notify() {
    for (final listener in _listeners.toList(growable: false)) {
      listener();
    }
  }
}
