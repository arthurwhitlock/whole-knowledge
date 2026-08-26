enum LearningItemKind { expression, vocabulary }

enum LearningItemStatus { active, archived }

final class LearningItem {
  const LearningItem({
    required this.id,
    required this.userId,
    required this.kind,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.nextReviewAt,
    required this.reviewCount,
    required this.productionCount,
    required this.status,
    this.meaning,
    this.context,
    this.source,
  });

  final String id;
  final String userId;
  final LearningItemKind kind;
  final String content;
  final String? meaning;
  final String? context;
  final String? source;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime nextReviewAt;
  final int reviewCount;
  final int productionCount;
  final LearningItemStatus status;

  bool isDueAt(DateTime instant) {
    return status == LearningItemStatus.active &&
        (reviewCount == 0 || !nextReviewAt.isAfter(instant));
  }
}
