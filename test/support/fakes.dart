import 'dart:async';

import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/application/auth/auth_session_repository.dart';
import 'package:whole_knowledge/application/learning/capture_learning_item.dart';
import 'package:whole_knowledge/application/learning/learning_item_repository.dart';
import 'package:whole_knowledge/application/learning/review_repository.dart';
import 'package:whole_knowledge/domain/auth/auth_session.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';
import 'package:whole_knowledge/domain/learning/review_schedule.dart';

final class FakeAuthSessionRepository implements AuthSessionRepository {
  FakeAuthSessionRepository({this.shouldFail = false});

  final bool shouldFail;
  int ensureCalls = 0;
  final session = const AuthSession(userId: 'user-1');

  @override
  AuthSession? get currentSession => ensureCalls == 0 ? null : session;

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();

  @override
  Future<AuthSession> ensureAnonymousSession() async {
    ensureCalls += 1;
    if (shouldFail) throw StateError('auth unavailable');
    return session;
  }
}

final class FakeLearningItemRepository implements LearningItemRepository {
  FakeLearningItemRepository({List<LearningItem> initialItems = const []})
    : items = List.of(initialItems);

  final List<LearningItem> items;
  CaptureLearningItem? lastCapture;
  Completer<void>? createGate;
  Completer<void>? loadGate;
  bool shouldFailCreate = false;
  bool shouldFailLoads = false;
  int createCalls = 0;
  int listAllCalls = 0;
  int listDueCalls = 0;

  @override
  Future<LearningItem> create(CaptureLearningItem capture) async {
    createCalls += 1;
    lastCapture = capture.normalized();
    await createGate?.future;
    if (shouldFailCreate) throw StateError('create unavailable');
    final now = DateTime.utc(
      2026,
      8,
      25,
      20,
    ).add(Duration(seconds: items.length));
    final item = learningItem(
      id: 'item-${items.length + 1}',
      content: lastCapture!.content,
      meaning: lastCapture!.meaning,
      context: lastCapture!.context,
      source: lastCapture!.source,
      kind: lastCapture!.kind,
      nextReviewAt: now,
    );
    items.insert(0, item);
    return item;
  }

  @override
  Future<List<LearningItem>> listAll() async {
    listAllCalls += 1;
    await loadGate?.future;
    if (shouldFailLoads) throw StateError('load unavailable');
    return List.unmodifiable(items);
  }

  @override
  Future<List<LearningItem>> listDue({required DateTime at}) async {
    listDueCalls += 1;
    await loadGate?.future;
    if (shouldFailLoads) throw StateError('load unavailable');
    return items.where((item) => item.isDueAt(at)).toList(growable: false);
  }
}

final class FakeReviewRepository implements ReviewRepository {
  FakeReviewRepository(this.learningItems);

  final FakeLearningItemRepository learningItems;
  ReviewRating? lastRating;
  String? lastResponse;
  String? lastSubmissionId;
  Completer<void>? completionGate;
  bool shouldFail = false;
  int completeCalls = 0;

  @override
  Future<LearningItem> completeReview({
    required LearningItem item,
    required String submissionId,
    required String responseText,
    required ReviewRating rating,
  }) async {
    completeCalls += 1;
    lastRating = rating;
    lastResponse = responseText;
    lastSubmissionId = submissionId;
    await completionGate?.future;
    if (shouldFail) throw StateError('review unavailable');
    final index = learningItems.items.indexWhere(
      (candidate) => candidate.id == item.id,
    );
    final previous = learningItems.items[index];
    final reviewedAt = DateTime.now().toUtc();
    final updated = learningItem(
      id: previous.id,
      content: previous.content,
      meaning: previous.meaning,
      context: previous.context,
      source: previous.source,
      kind: previous.kind,
      nextReviewAt: ReviewSchedule.nextReviewAt(rating, reviewedAt),
      reviewCount: previous.reviewCount + 1,
      productionCount: previous.productionCount + 1,
    );
    learningItems.items[index] = updated;
    return updated;
  }
}

AppDependencies fakeDependencies({List<LearningItem> items = const []}) {
  final learningItems = FakeLearningItemRepository(initialItems: items);
  return AppDependencies(
    authSessions: FakeAuthSessionRepository(),
    learningItems: learningItems,
    reviews: FakeReviewRepository(learningItems),
  );
}

LearningItem learningItem({
  String id = 'item-1',
  String content = 'prendre son temps',
  String? meaning = 'to take one’s time',
  String? context,
  String? source,
  LearningItemKind kind = LearningItemKind.expression,
  DateTime? nextReviewAt,
  int reviewCount = 0,
  int productionCount = 0,
}) {
  final createdAt = DateTime.utc(2026, 8, 25, 20);
  return LearningItem(
    id: id,
    userId: 'user-1',
    kind: kind,
    content: content,
    meaning: meaning,
    context: context,
    source: source,
    createdAt: createdAt,
    updatedAt: createdAt,
    nextReviewAt: nextReviewAt ?? createdAt,
    reviewCount: reviewCount,
    productionCount: productionCount,
    status: LearningItemStatus.active,
  );
}
