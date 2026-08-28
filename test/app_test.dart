import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:whole_knowledge/app/app.dart';
import 'package:whole_knowledge/application/capture/capture_draft.dart';
import 'package:whole_knowledge/domain/learning/review_attempt.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('handles missing Supabase configuration gracefully', (
    tester,
  ) async {
    await tester.pumpWidget(
      const WholeKnowledgeApp(backendMessage: 'Development config is absent.'),
    );

    expect(find.text('Whole Knowledge'), findsOneWidget);
    expect(find.text('The learning workspace is unavailable.'), findsOneWidget);
    expect(find.text('Development config is absent.'), findsOneWidget);
  });

  testWidgets('provides both light and dark themes', (tester) async {
    await tester.pumpWidget(const WholeKnowledgeApp());

    final app = tester.widget<ShadApp>(find.byType(ShadApp));

    expect(app.theme?.brightness, Brightness.light);
    expect(app.darkTheme?.brightness, Brightness.dark);
    expect(app.themeMode, ThemeMode.system);
  });

  testWidgets('uses bottom navigation on a narrow layout', (tester) async {
    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      WholeKnowledgeApp(dependencies: fakeDependencies()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Today'), findsWidgets);
    expect(find.byKey(const ValueKey('today-review-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('today-context-rail')), findsOneWidget);
  });

  testWidgets('uses a navigation rail on a wide layout', (tester) async {
    await _setViewport(tester, const Size(1200, 800));
    await tester.pumpWidget(
      WholeKnowledgeApp(dependencies: fakeDependencies()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('loads Library only after the first visit', (tester) async {
    final dependencies = fakeDependencies(items: [learningItem()]);
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(learningItems.listPageCalls, 0);

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    expect(learningItems.listPageCalls, 1);
  });

  testWidgets('recovers from an initial learning-item load failure', (
    tester,
  ) async {
    final dependencies = fakeDependencies();
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    learningItems.shouldFailLoads = true;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('Could not load your learning items.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    learningItems.shouldFailLoads = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing is due right now.'), findsOneWidget);
    expect(find.text('Could not load your learning items.'), findsNothing);
  });

  testWidgets('validates and saves a capture', (tester) async {
    await _setViewport(tester, const Size(390, 844));
    final dependencies = fakeDependencies();
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();
    expect(find.text('What did you find?'), findsOneWidget);
    expect(find.text('Make it understandable'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('capture-supporting-details')),
      findsOneWidget,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-capture')));
    await tester.tap(find.byKey(const ValueKey('save-capture')));
    await tester.pump();
    expect(find.text('Enter the language you encountered.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      '  pourtant  ',
    );
    await tester.enterText(
      find.byKey(const ValueKey('capture-meaning')),
      ' however ',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-capture')));
    await tester.tap(find.byKey(const ValueKey('save-capture')));
    await tester.pumpAndSettle();

    expect(learningItems.lastCapture?.content, 'pourtant');
    expect(learningItems.lastCapture?.meaning, 'however');
    expect(find.text('1 item ready for review.'), findsOneWidget);
  });

  testWidgets('routes a meaningful cold-start draft to Capture', (
    tester,
  ) async {
    final dependencies = fakeDependencies();
    final drafts = dependencies.captureDrafts as FakeCaptureDraftRepository;
    drafts.saved = const CaptureDraft(
      content: 'restored word',
      meaning: 'restored meaning',
    );

    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    expect(find.text('Draft restored'), findsOneWidget);
    expect(find.text('restored word'), findsOneWidget);
    expect(find.text('restored meaning'), findsOneWidget);
  });

  testWidgets('choosing an English sense fills editable meaning and POS', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    final dependencies = fakeDependencies();
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      'record',
    );
    await tester.pump();
    final lookupButton = tester.widget<ShadButton>(
      find.byKey(const ValueKey('lookup-meaning')),
    );
    expect(lookupButton.enabled, isTrue);
    await tester.ensureVisible(find.byKey(const ValueKey('lookup-meaning')));
    await tester.tap(find.byKey(const ValueKey('lookup-meaning')));
    await tester.pumpAndSettle();
    expect(
      (dependencies.lexicalProvider as FakeLexicalProvider).lookupCalls,
      1,
    );
    final verbSense = find.textContaining('To preserve information.');
    expect(verbSense, findsOneWidget);
    await tester.ensureVisible(verbSense);
    await tester.tap(verbSense);
    await tester.pumpAndSettle();

    expect(find.text('To preserve information.'), findsOneWidget);
    expect(find.text('verb'), findsOneWidget);
    expect(find.text('Test dictionary attribution'), findsOneWidget);
  });

  testWidgets('opens adaptive library detail and existing review history', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    final item = learningItem(partOfSpeech: 'verb', reviewCount: 1);
    final dependencies = fakeDependencies(items: [item]);
    final reviews = dependencies.reviews as FakeReviewRepository;
    reviews.attempts.add(
      ReviewAttempt(
        id: 'attempt-1',
        userId: 'user-1',
        learningItemId: item.id,
        reviewSubmissionId: 'submission-1',
        attemptType: ReviewAttemptType.production,
        rating: ReviewRating.good,
        responseText: 'Je prends mon temps.',
        createdAt: DateTime.utc(2026, 8, 26),
      ),
    );
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('library-item-${item.id}')));
    await tester.pumpAndSettle();

    expect(find.text('Review history'), findsOneWidget);
    expect(find.text('Je prends mon temps.'), findsOneWidget);
    expect(find.text('verb'), findsOneWidget);
    expect(find.text('Library'), findsWidgets);
    expect(
      find.byKey(const ValueKey('library-learning-summary')),
      findsOneWidget,
    );
  });

  testWidgets('ignores stale history after a fast wide-layout selection', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1200, 800));
    final first = learningItem(id: 'item-a', content: 'first item');
    final second = learningItem(id: 'item-b', content: 'second item');
    final dependencies = fakeDependencies(items: [first, second]);
    final reviews = dependencies.reviews as FakeReviewRepository;
    reviews.attemptGates[first.id] = Completer<List<ReviewAttempt>>();
    reviews.attempts.add(
      ReviewAttempt(
        id: 'attempt-b',
        userId: 'user-1',
        learningItemId: second.id,
        reviewSubmissionId: 'submission-b',
        attemptType: ReviewAttemptType.production,
        rating: ReviewRating.good,
        responseText: 'second response',
        createdAt: DateTime.utc(2026, 8, 27),
      ),
    );
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-item-item-a')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('library-item-item-b')));
    await tester.pumpAndSettle();

    reviews.attemptGates[first.id]!.complete([
      ReviewAttempt(
        id: 'attempt-a',
        userId: 'user-1',
        learningItemId: first.id,
        reviewSubmissionId: 'submission-a',
        attemptType: ReviewAttemptType.production,
        rating: ReviewRating.hard,
        responseText: 'stale first response',
        createdAt: DateTime.utc(2026, 8, 27),
      ),
    ]);
    await tester.pumpAndSettle();

    expect(find.text('second response'), findsOneWidget);
    expect(find.text('stale first response'), findsNothing);
  });

  testWidgets('preserves a capture draft across the adaptive breakpoint', (
    tester,
  ) async {
    await _setViewport(tester, const Size(759, 844));
    await tester.pumpWidget(
      WholeKnowledgeApp(dependencies: fakeDependencies()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      'Draft survives resizing',
    );

    tester.view.physicalSize = const Size(761, 844);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.text('Draft survives resizing'), findsOneWidget);
  });

  testWidgets('locks a capture while saving and ignores duplicate taps', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    final dependencies = fakeDependencies();
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    learningItems.createGate = Completer<void>();
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      'still here',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-capture')));
    await tester.tap(find.byKey(const ValueKey('save-capture')));
    await tester.pump();

    expect(
      tester
          .widget<ShadTextarea>(find.byKey(const ValueKey('capture-content')))
          .enabled,
      isFalse,
    );
    // The button is intentionally disabled while the create call is in flight.
    await tester.tap(
      find.byKey(const ValueKey('save-capture')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(learningItems.createCalls, 1);

    learningItems.createGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('preserves every capture field when saving fails', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    final dependencies = fakeDependencies();
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    learningItems.shouldFailCreate = true;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      'preserved language',
    );
    await tester.enterText(
      find.byKey(const ValueKey('capture-meaning')),
      'preserved meaning',
    );
    await tester.enterText(
      find.byKey(const ValueKey('capture-context')),
      'preserved context',
    );
    await tester.enterText(
      find.byKey(const ValueKey('capture-source')),
      'preserved source',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('save-capture')));
    await tester.tap(find.byKey(const ValueKey('save-capture')));
    await tester.pumpAndSettle();

    expect(find.text('preserved language'), findsOneWidget);
    expect(find.text('preserved meaning'), findsOneWidget);
    expect(find.text('preserved context'), findsOneWidget);
    expect(find.text('preserved source'), findsOneWidget);
    expect(
      find.text('Could not save this item. Your input is still here.'),
      findsOneWidget,
    );

    learningItems.shouldFailCreate = false;
    await tester.ensureVisible(find.byKey(const ValueKey('save-capture')));
    await tester.tap(find.byKey(const ValueKey('save-capture')));
    await tester.pumpAndSettle();
    expect(learningItems.createCalls, 2);
    expect(learningItems.lastCapture?.content, 'preserved language');
  });

  testWidgets('preserves the first capture draft during a background reload', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    final dependencies = fakeDependencies();
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('capture-content')),
      'draft survives reload',
    );
    learningItems.loadGate = Completer<void>();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('draft survives reload'), findsOneWidget);
    learningItems.loadGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('draft survives reload'), findsOneWidget);
  });

  testWidgets('completes retrieval, production, and self-rating', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1200, 800));
    final dependencies = fakeDependencies(items: [learningItem()]);
    final reviews = dependencies.reviews as FakeReviewRepository;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('start-review')));
    await tester.pump();
    expect(
      find.text('Recall the meaning before revealing your notes.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('review-stage-progress')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('reveal-answer')));
    await tester.pump();
    expect(find.text('to take one’s time'), findsOneWidget);

    await tester.tap(find.text('Continue to production'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('production-response')),
      'Je prends mon temps.',
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-rating')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rating-good')));
    await tester.pumpAndSettle();

    expect(reviews.lastRating, ReviewRating.good);
    expect(reviews.lastResponse, 'Je prends mon temps.');
    expect(find.text('Review complete.'), findsOneWidget);
  });

  testWidgets('refreshes Library item and history after a completed review', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1200, 800));
    final dependencies = fakeDependencies(items: [learningItem()]);
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('library-item-item-1')));
    await tester.pumpAndSettle();
    expect(find.text('No review attempts yet.'), findsOneWidget);
    final initialPageCalls = learningItems.listPageCalls;

    await tester.tap(find.text('Today').last);
    await tester.pumpAndSettle();
    await _enterProduction(tester);
    await tester.enterText(
      find.byKey(const ValueKey('production-response')),
      'The refreshed response',
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-rating')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rating-good')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    expect(learningItems.listPageCalls, initialPageCalls + 1);
    await tester.tap(find.byKey(const ValueKey('library-item-item-1')));
    await tester.pumpAndSettle();

    expect(find.text('The refreshed response'), findsOneWidget);
    expect(find.text('No review attempts yet.'), findsNothing);
  });

  testWidgets('preserves an active production response when resizing', (
    tester,
  ) async {
    await _setViewport(tester, const Size(759, 844));
    await tester.pumpWidget(
      WholeKnowledgeApp(
        dependencies: fakeDependencies(items: [learningItem()]),
      ),
    );
    await tester.pumpAndSettle();
    await _enterProduction(tester);
    await tester.enterText(
      find.byKey(const ValueKey('production-response')),
      'Je garde ma réponse.',
    );

    tester.view.physicalSize = const Size(761, 844);
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Je garde ma réponse.'), findsOneWidget);
    expect(find.text('Continue to self-rating'), findsOneWidget);
  });

  testWidgets('Android system back pauses review and restores navigation', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      WholeKnowledgeApp(
        dependencies: fakeDependencies(items: [learningItem()]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('start-review')));
    await tester.pump();

    expect(find.byType(NavigationBar), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byKey(const ValueKey('resume-review')), findsOneWidget);
  });

  testWidgets('retries an ambiguous review with immutable idempotency data', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1200, 800));
    final dependencies = fakeDependencies(items: [learningItem()]);
    final reviews = dependencies.reviews as FakeReviewRepository;
    reviews.shouldFail = true;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await _enterProduction(tester);
    await tester.enterText(
      find.byKey(const ValueKey('production-response')),
      'First response',
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-rating')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rating-hard')));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Could not confirm this review. Retry safely with the same response, '
        'or discard it and reload the queue.',
      ),
      findsOneWidget,
    );
    final response = tester.widget<ShadTextarea>(
      find.byKey(const ValueKey('production-response')),
    );
    expect(response.readOnly, isTrue);
    expect(response.enabled, isTrue);
    expect(find.text('First response'), findsOneWidget);
    expect(find.byKey(const ValueKey('rating-hard')), findsNothing);
    expect(find.byKey(const ValueKey('retry-review')), findsOneWidget);
    final failedSubmissionId = reviews.lastSubmissionId;

    reviews.shouldFail = false;
    await tester.tap(find.byKey(const ValueKey('retry-review')));
    await tester.pumpAndSettle();

    expect(reviews.completeCalls, 2);
    expect(reviews.lastResponse, 'First response');
    expect(reviews.lastRating, ReviewRating.hard);
    expect(reviews.lastSubmissionId, failedSubmissionId);
    expect(find.text('Review complete.'), findsOneWidget);
  });

  testWidgets('hides stale review actions while a discarded review reloads', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1200, 800));
    final dependencies = fakeDependencies(items: [learningItem()]);
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    final reviews = dependencies.reviews as FakeReviewRepository;
    reviews.shouldFail = true;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await _enterProduction(tester);
    await tester.enterText(
      find.byKey(const ValueKey('production-response')),
      'Discard this ambiguous response',
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-rating')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rating-good')));
    await tester.pumpAndSettle();

    learningItems.loadGate = Completer<void>();
    await tester.tap(find.byKey(const ValueKey('reload-review-queue')));
    await tester.pump();

    expect(find.text('Refreshing review queue.'), findsOneWidget);
    expect(find.byKey(const ValueKey('start-review')), findsNothing);

    learningItems.loadGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Refreshing review queue.'), findsNothing);
    expect(find.byKey(const ValueKey('start-review')), findsOneWidget);
  });

  testWidgets('submits a review only once while a request is in flight', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1200, 800));
    final dependencies = fakeDependencies(items: [learningItem()]);
    final reviews = dependencies.reviews as FakeReviewRepository;
    reviews.completionGate = Completer<void>();
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await _enterProduction(tester);
    await tester.enterText(
      find.byKey(const ValueKey('production-response')),
      'One request',
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-rating')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rating-good')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rating-good')));
    await tester.pump();

    expect(reviews.completeCalls, 1);

    reviews.completionGate!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('keeps a completed item out of Today when reconciliation fails', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1200, 800));
    final dependencies = fakeDependencies(items: [learningItem()]);
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await _enterProduction(tester);
    await tester.enterText(
      find.byKey(const ValueKey('production-response')),
      'Saved locally in UI',
    );
    await tester.tap(find.byKey(const ValueKey('continue-to-rating')));
    await tester.pump();
    learningItems.shouldFailLoads = true;
    await tester.tap(find.byKey(const ValueKey('rating-good')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('start-review')), findsNothing);
    expect(find.text('Nothing is due right now.'), findsOneWidget);
    expect(find.text('Could not load your learning items.'), findsOneWidget);
  });

  testWidgets('refreshes the due queue on resume and at the next due time', (
    tester,
  ) async {
    await _setViewport(tester, const Size(1200, 800));
    final nextDueAt = DateTime.now().toUtc().add(const Duration(hours: 1));
    final dependencies = fakeDependencies(
      items: [learningItem(reviewCount: 1, nextReviewAt: nextDueAt)],
    );
    final learningItems =
        dependencies.learningItems as FakeLearningItemRepository;
    await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    final initialCalls = learningItems.listDueCalls;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(learningItems.listDueCalls, greaterThan(initialCalls));
    final resumedCalls = learningItems.listDueCalls;

    await tester.pump(const Duration(hours: 2));
    await tester.pump();
    expect(learningItems.listDueCalls, greaterThan(resumedCalls));
  });

  testWidgets('exposes selected capture type and live validation semantics', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      WholeKnowledgeApp(dependencies: fakeDependencies()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Language, required'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('save-capture')));
    await tester.tap(find.byKey(const ValueKey('save-capture')));
    await tester.pump();
    expect(find.text('Enter the language you encountered.'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('core screens reflow at an enlarged text scale', (tester) async {
    await _setViewport(tester, const Size(390, 844));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      WholeKnowledgeApp(
        dependencies: fakeDependencies(items: [learningItem()]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('today-review-surface')), findsOneWidget);

    await tester.tap(find.text('Capture').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('capture-content')), findsOneWidget);

    await tester.tap(find.text('Library').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-item-item-1')), findsOneWidget);
  });
}

Future<void> _enterProduction(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('start-review')));
  await tester.pump();
  await tester.tap(find.byKey(const ValueKey('reveal-answer')));
  await tester.pump();
  await tester.tap(find.text('Continue to production'));
  await tester.pump();
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
