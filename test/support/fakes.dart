import 'dart:async';

import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/application/auth/auth_session_repository.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/application/capture/lexical_provider.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/application/capture/discovery_validation.dart';
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
  int listPageCalls = 0;
  final Map<String, DiscoverySubmission> discoverySubmissions = {};

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
      partOfSpeech: lastCapture!.partOfSpeech,
      kind: lastCapture!.kind,
      nextReviewAt: now,
    );
    items.insert(0, item);
    return item;
  }

  @override
  Future<List<LearningItem>> findActiveBySurfaceForm(String content) async {
    final key = DiscoveryValidation.surfaceMatchKey(content);
    return items
        .where(
          (item) =>
              item.status == LearningItemStatus.active &&
              DiscoveryValidation.surfaceMatchKey(item.content) == key,
        )
        .toList(growable: false);
  }

  @override
  Future<DiscoveryCompletion> completeDiscovery(
    DiscoverySubmission submission,
  ) async {
    final normalized = submission.normalized();
    final prior = discoverySubmissions[normalized.submissionId];
    if (prior != null) {
      if (!prior.hasSamePayload(normalized)) {
        throw StateError('Discovery submission conflict');
      }
      final item = items.firstWhere(
        (candidate) => candidate.id == 'discovery-${normalized.submissionId}',
      );
      return DiscoveryReplayed(item);
    }
    final matches = await findActiveBySurfaceForm(normalized.content);
    if (matches.isNotEmpty && !normalized.allowExistingSurface) {
      return DiscoveryExistingSurface(matches.first);
    }
    final now = DateTime.utc(
      2026,
      8,
      30,
      19,
    ).add(Duration(seconds: items.length));
    final item = learningItem(
      id: 'discovery-${normalized.submissionId}',
      content: normalized.content,
      meaning: normalized.meaning,
      context: normalized.context,
      source: normalized.source,
      firstProduction: normalized.firstProduction,
      partOfSpeech: normalized.partOfSpeech,
      kind: normalized.kind,
      nextReviewAt: normalized.firstProduction == null
          ? now
          : now.add(const Duration(hours: 24)),
    );
    discoverySubmissions[normalized.submissionId] = normalized;
    items.insert(0, item);
    return DiscoveryCreated(item);
  }

  @override
  Future<List<LearningItem>> listAll() async {
    listAllCalls += 1;
    await loadGate?.future;
    if (shouldFailLoads) throw StateError('load unavailable');
    return List.unmodifiable(items);
  }

  @override
  Future<List<LearningItem>> listDue({
    required DateTime at,
    int limit = 100,
  }) async {
    listDueCalls += 1;
    await loadGate?.future;
    if (shouldFailLoads) throw StateError('load unavailable');
    return items
        .where((item) => item.isDueAt(at))
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<List<LearningItem>> listRecent({required int limit}) async {
    await loadGate?.future;
    if (shouldFailLoads) throw StateError('load unavailable');
    return items.take(limit).toList(growable: false);
  }

  @override
  Future<List<LearningItem>> listCompletedBetween({
    required DateTime from,
    required DateTime to,
    required int limit,
  }) async {
    await loadGate?.future;
    if (shouldFailLoads) throw StateError('load unavailable');
    return items
        .where(
          (item) =>
              item.reviewCount > 0 &&
              !item.updatedAt.isBefore(from) &&
              item.updatedAt.isBefore(to),
        )
        .take(limit)
        .toList(growable: false);
  }

  @override
  Future<DateTime?> findNextScheduled({required DateTime after}) async {
    await loadGate?.future;
    if (shouldFailLoads) throw StateError('load unavailable');
    final candidates =
        items
            .map((item) => item.nextReviewAt)
            .where((value) => value.isAfter(after))
            .toList()
          ..sort();
    return candidates.firstOrNull;
  }

  @override
  Future<List<LearningItem>> listPage({
    required int offset,
    required int limit,
  }) async {
    listPageCalls += 1;
    await loadGate?.future;
    if (shouldFailLoads) throw StateError('load unavailable');
    return items.skip(offset).take(limit).toList(growable: false);
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
  final List<ReviewAttempt> attempts = [];
  final Map<String, Completer<List<ReviewAttempt>>> attemptGates = {};

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
      firstProduction: previous.firstProduction,
      lastReviewedAt: reviewedAt,
      partOfSpeech: previous.partOfSpeech,
      kind: previous.kind,
      nextReviewAt: ReviewSchedule.nextReviewAt(rating, reviewedAt),
      reviewCount: previous.reviewCount + 1,
      productionCount: previous.productionCount + 1,
    );
    learningItems.items[index] = updated;
    attempts.insert(
      0,
      ReviewAttempt(
        id: 'attempt-$completeCalls',
        userId: updated.userId,
        learningItemId: updated.id,
        reviewSubmissionId: submissionId,
        attemptType: ReviewAttemptType.production,
        rating: rating,
        responseText: responseText,
        createdAt: reviewedAt,
      ),
    );
    return updated;
  }

  @override
  Future<List<ReviewAttempt>> listAttempts({
    required String learningItemId,
    required int offset,
    required int limit,
  }) async {
    final gated = attemptGates[learningItemId];
    if (gated != null) return gated.future;
    return attempts
        .where((attempt) => attempt.learningItemId == learningItemId)
        .skip(offset)
        .take(limit)
        .toList(growable: false);
  }
}

final class FakeCaptureDraftRepository implements CaptureDraftRepository {
  CaptureDraft? saved;
  int writes = 0;
  int clears = 0;
  bool shouldFailRead = false;
  bool shouldFailWrite = false;
  bool shouldFailClear = false;

  @override
  Future<CaptureDraft?> read() async {
    if (shouldFailRead) throw StateError('read unavailable');
    return saved;
  }

  @override
  Future<void> write(CaptureDraft draft) async {
    if (shouldFailWrite) throw StateError('write unavailable');
    writes += 1;
    saved = draft;
  }

  @override
  Future<void> clear() async {
    if (shouldFailClear) throw StateError('clear unavailable');
    clears += 1;
    saved = null;
  }
}

final class FakeLexicalProvider implements LexicalProvider {
  LexicalLookup result = const LexicalLookup(
    term: 'record',
    senses: [
      LexicalSense(partOfSpeech: 'noun', definition: 'A stored account.'),
      LexicalSense(
        partOfSpeech: 'verb',
        definition: 'To preserve information.',
      ),
    ],
  );
  Object? error;
  int lookupCalls = 0;

  @override
  String get attribution => 'Test dictionary attribution';

  @override
  Future<LexicalLookup> lookup(String term) async {
    lookupCalls += 1;
    if (error case final value?) throw value;
    return result;
  }
}

AppDependencies fakeDependencies({List<LearningItem> items = const []}) {
  final learningItems = FakeLearningItemRepository(initialItems: items);
  return AppDependencies(
    authSessions: FakeAuthSessionRepository(),
    learningItems: learningItems,
    reviews: FakeReviewRepository(learningItems),
    captureDrafts: FakeCaptureDraftRepository(),
    lexicalProvider: FakeLexicalProvider(),
  );
}

LearningItem learningItem({
  String id = 'item-1',
  String content = 'prendre son temps',
  String? meaning = 'to take one’s time',
  String? context,
  String? source,
  String? partOfSpeech,
  String? firstProduction,
  DateTime? lastReviewedAt,
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
    partOfSpeech: partOfSpeech,
    firstProduction: firstProduction,
    lastReviewedAt: lastReviewedAt,
    createdAt: createdAt,
    updatedAt: createdAt,
    nextReviewAt: nextReviewAt ?? createdAt,
    reviewCount: reviewCount,
    productionCount: productionCount,
    status: LearningItemStatus.active,
  );
}
