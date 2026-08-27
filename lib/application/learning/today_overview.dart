import 'package:whole_knowledge/application/learning/learning_item_repository.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';

final class TodayOverview {
  const TodayOverview({
    required this.dueItems,
    required this.recentlyCaptured,
    required this.completedToday,
    required this.nextReviewAt,
  });

  final List<LearningItem> dueItems;
  final List<LearningItem> recentlyCaptured;
  final List<LearningItem> completedToday;
  final DateTime? nextReviewAt;
}

final class LoadTodayOverview {
  const LoadTodayOverview(this._learningItems);

  final LearningItemRepository _learningItems;

  Future<TodayOverview> call({required DateTime now}) async {
    final localNow = now.toLocal();
    final localStart = DateTime(localNow.year, localNow.month, localNow.day);
    final localEnd = DateTime(localNow.year, localNow.month, localNow.day + 1);
    final results = await Future.wait<Object?>([
      _learningItems.listDue(at: now.toUtc(), limit: 100),
      _learningItems.listRecent(limit: 5),
      _learningItems.listCompletedBetween(
        from: localStart.toUtc(),
        to: localEnd.toUtc(),
        limit: 5,
      ),
      _learningItems.findNextScheduled(after: now.toUtc()),
    ]);
    return TodayOverview(
      dueItems: results[0] as List<LearningItem>,
      recentlyCaptured: results[1] as List<LearningItem>,
      completedToday: results[2] as List<LearningItem>,
      nextReviewAt: results[3] as DateTime?,
    );
  }
}
