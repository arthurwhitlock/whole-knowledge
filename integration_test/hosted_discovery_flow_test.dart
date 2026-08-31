import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/app/app.dart';
import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/application/capture/discovery_failure.dart';
import 'package:whole_knowledge/application/capture/discovery_submission.dart';
import 'package:whole_knowledge/application/learning/learning_item_repository.dart';
import 'package:whole_knowledge/domain/learning/learning_item.dart';
import 'package:whole_knowledge/infrastructure/dictionary/english_dictionary_api_provider.dart';
import 'package:whole_knowledge/infrastructure/local/file_capture_draft_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_auth_session_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_learning_item_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_review_repository.dart';

const _hostedValidation = bool.fromEnvironment('HOSTED_VALIDATION');
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Frankfurt Capture persists across restart and returns Review to Capture',
    (tester) async {
      expect(_supabaseUrl, contains('vubjubgyusjvsvawxzdn.supabase.co'));
      expect(_supabaseKey, isNotEmpty);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final draftDirectory = await Directory.systemTemp.createTemp(
        'whole-knowledge-hosted-',
      );
      final clients = <SupabaseClient>[];
      final createdIds = <String>[];
      SupabaseClient? cleanupClient;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        if (cleanupClient != null && createdIds.isNotEmpty) {
          await cleanupClient
              .from('learning_items')
              .delete()
              .inFilter('id', createdIds);
        }
        for (final client in clients) {
          await client.dispose();
        }
        if (await draftDirectory.exists()) {
          await draftDirectory.delete(recursive: true);
        }
      });

      final firstClient = SupabaseClient(_supabaseUrl, _supabaseKey);
      clients.add(firstClient);
      cleanupClient = firstClient;
      final signedIn = await firstClient.auth.signInAnonymously();
      final firstSession = signedIn.session!;
      final firstItems = SupabaseLearningItemRepository(firstClient);

      await _launch(
        tester,
        dependencies: _dependencies(firstClient, draftDirectory),
      );
      await _openCapture(tester);
      await tester.enterText(
        find.byKey(const ValueKey('capture-content')),
        'serendipity',
      );
      await _tapKey(tester, 'discover-language');
      await _waitFor(tester, find.byKey(const ValueKey('sense-group-0')));

      final firstSense = find
          .descendant(
            of: find.byKey(const ValueKey('sense-group-0')),
            matching: find.byType(InkWell),
          )
          .first;
      await tester.ensureVisible(firstSense);
      await tester.tap(firstSense);
      await _waitFor(
        tester,
        find.byKey(const ValueKey('selected-meaning-summary')),
      );
      await _tapKey(tester, 'continue-to-production');
      await _waitFor(tester, find.byKey(const ValueKey('first-production')));
      await tester.enterText(
        find.byKey(const ValueKey('first-production')),
        'Finding this note again was a happy serendipity.',
      );
      await _tapKey(tester, 'complete-discovery');
      await _waitFor(tester, find.text('Discovered'));

      final saved = await firstItems.findActiveBySurfaceForm('serendipity');
      expect(saved, hasLength(1));
      final item = saved.single;
      createdIds.add(item.id);
      expect(
        item.firstProduction,
        'Finding this note again was a happy serendipity.',
      );
      expect(item.partOfSpeech, isNotEmpty);
      expect(
        item.nextReviewAt.difference(item.createdAt),
        closeToDuration(const Duration(hours: 24)),
      );

      await _tapKey(tester, 'discovery-done');
      await _waitFor(tester, find.byKey(const ValueKey('today-overview')));
      await _waitFor(tester, find.text('serendipity'));
      expect(find.text('serendipity'), findsWidgets);
      await _openLibrary(tester);
      await _waitFor(tester, find.byKey(ValueKey('library-item-${item.id}')));
      await _tapKey(tester, 'library-item-${item.id}');
      await _waitFor(tester, find.byKey(ValueKey('library-detail-${item.id}')));
      expect(
        find.byKey(const ValueKey('library-learning-summary')),
        findsOneWidget,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      final restartedClient = SupabaseClient(_supabaseUrl, _supabaseKey);
      clients.add(restartedClient);
      cleanupClient = restartedClient;
      final restoredAuth = await restartedClient.auth.setSession(
        firstSession.refreshToken!,
        accessToken: firstSession.accessToken,
      );
      expect(restoredAuth.user?.id, firstSession.user.id);
      await restartedClient.auth.refreshSession();
      final restartedItems = SupabaseLearningItemRepository(restartedClient);
      await _launch(
        tester,
        dependencies: _dependencies(restartedClient, draftDirectory),
      );
      await _waitFor(tester, find.byKey(const ValueKey('today-overview')));
      expect(
        (await restartedItems.findActiveBySurfaceForm('serendipity')).single.id,
        item.id,
      );
      await _openLibrary(tester);
      await _waitFor(tester, find.byKey(ValueKey('library-item-${item.id}')));

      await _openCapture(tester);
      await tester.enterText(
        find.byKey(const ValueKey('capture-content')),
        '  SERENDIPITY  ',
      );
      await _tapKey(tester, 'discover-language');
      await _waitFor(tester, find.byKey(const ValueKey('reencounter')));
      expect(find.text('Already in your knowledge'), findsOneWidget);
      await _tapKey(tester, 'test-myself');
      await _waitFor(tester, find.byKey(const ValueKey('review-focus')));

      await _tapKey(tester, 'pause-review');
      await _waitFor(
        tester,
        find.byKey(const ValueKey('resume-targeted-review')),
      );
      expect(find.text('Already in your knowledge'), findsOneWidget);
      await _tapKey(tester, 'resume-targeted-review');
      await _waitFor(tester, find.byKey(const ValueKey('review-focus')));

      await _tapKey(tester, 'reveal-answer');
      await _tapText(tester, 'Continue to production');
      await _waitFor(tester, find.byKey(const ValueKey('production-response')));
      await tester.enterText(
        find.byKey(const ValueKey('production-response')),
        'The rediscovered passage felt like serendipity.',
      );
      await _tapKey(tester, 'continue-to-rating');
      await _tapKey(tester, 'rating-good');
      await _waitFor(tester, find.byKey(const ValueKey('reencounter')));
      expect(find.text('Already in your knowledge'), findsOneWidget);

      final reviewed = (await restartedItems.findActiveBySurfaceForm(
        'serendipity',
      )).single;
      expect(reviewed.reviewCount, 1);
      expect(reviewed.productionCount, 1);
      expect(reviewed.lastReviewedAt, isNotNull);

      await _openLibrary(tester);
      await _waitFor(
        tester,
        find.byKey(ValueKey('library-item-${reviewed.id}')),
      );
      await _tapKey(tester, 'library-item-${reviewed.id}');
      await _waitFor(tester, find.text('Production'));
      expect(
        find.text('The rediscovered passage felt like serendipity.'),
        findsOneWidget,
      );
    },
    skip: !_hostedValidation,
  );

  testWidgets(
    'Frankfurt recovery restores draft and reconciles the same submission',
    (tester) async {
      expect(_supabaseUrl, contains('vubjubgyusjvsvawxzdn.supabase.co'));
      expect(_supabaseKey, isNotEmpty);

      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 900);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final draftDirectory = await Directory.systemTemp.createTemp(
        'whole-knowledge-recovery-',
      );
      final client = SupabaseClient(_supabaseUrl, _supabaseKey);
      await client.auth.signInAnonymously();
      final delegate = SupabaseLearningItemRepository(client);
      final items = _RecoveryLearningItemRepository(delegate);
      final runToken = DateTime.now().toUtc().microsecondsSinceEpoch;
      final content = 'WK recovery expression $runToken';
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await client.from('learning_items').delete().eq('content', content);
        await client.dispose();
        if (await draftDirectory.exists()) {
          await draftDirectory.delete(recursive: true);
        }
      });

      AppDependencies dependencies() =>
          _dependencies(client, draftDirectory, learningItems: items);

      await _launch(tester, dependencies: dependencies());
      await _openCapture(tester);
      await tester.enterText(
        find.byKey(const ValueKey('capture-content')),
        content,
      );
      await _tapText(tester, 'Enter meaning manually');
      await _waitFor(tester, find.byKey(const ValueKey('capture-meaning')));
      await _waitFor(tester, find.byKey(const ValueKey('library-failed')));
      await tester.enterText(
        find.byKey(const ValueKey('capture-meaning')),
        'a deterministic recovery fixture',
      );

      final libraryRetry = find.descendant(
        of: find.byKey(const ValueKey('library-failed')),
        matching: find.text('Retry'),
      );
      await tester.tap(libraryRetry);
      await _waitFor(tester, find.byKey(const ValueKey('library-clear')));
      await _tapKey(tester, 'continue-to-production');
      await tester.enterText(
        find.byKey(const ValueKey('first-production')),
        'This expression survives a local restart.',
      );
      await tester.pump(const Duration(milliseconds: 600));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies()));
      await _waitFor(tester, find.byKey(const ValueKey('draft-restored')));
      await _waitFor(tester, find.byKey(const ValueKey('first-production')));
      await _waitFor(tester, find.byKey(const ValueKey('library-clear')));
      final restoredProduction = tester.widget<EditableText>(
        find.descendant(
          of: find.byKey(const ValueKey('first-production')),
          matching: find.byType(EditableText),
        ),
      );
      expect(
        restoredProduction.controller.text,
        'This expression survives a local restart.',
      );

      await _tapKey(tester, 'complete-discovery');
      await _waitFor(
        tester,
        find.byKey(const ValueKey('retry-discovery-submission')),
      );
      expect(items.submissionIds, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies()));
      await _waitFor(
        tester,
        find.byKey(const ValueKey('retry-discovery-submission')),
      );
      await _tapKey(tester, 'retry-discovery-submission');
      await _waitFor(tester, find.text('Discovered'));

      expect(items.submissionIds, hasLength(2));
      expect(items.submissionIds.toSet(), hasLength(1));
      final saved = await delegate.findActiveBySurfaceForm(content);
      expect(saved, hasLength(1));
      expect(
        saved.single.firstProduction,
        'This expression survives a local restart.',
      );
    },
    skip: !_hostedValidation,
  );
}

AppDependencies _dependencies(
  SupabaseClient client,
  Directory draftDirectory, {
  LearningItemRepository? learningItems,
}) => AppDependencies(
  authSessions: SupabaseAuthSessionRepository(client),
  learningItems: learningItems ?? SupabaseLearningItemRepository(client),
  reviews: SupabaseReviewRepository(client),
  captureDrafts: FileCaptureDraftRepository(
    directoryProvider: () async => draftDirectory,
  ),
  lexicalProvider: EnglishDictionaryApiProvider(),
);

Future<void> _launch(
  WidgetTester tester, {
  required AppDependencies dependencies,
}) async {
  await tester.pumpWidget(WholeKnowledgeApp(dependencies: dependencies));
  await _waitFor(tester, find.byKey(const ValueKey('today-overview')));
}

Future<void> _openCapture(WidgetTester tester) async {
  await _tapText(tester, 'Capture', last: true);
  await _waitFor(tester, find.byKey(const ValueKey('capture-content')));
}

Future<void> _openLibrary(WidgetTester tester) async {
  await _tapText(tester, 'Library', last: true);
  await _waitFor(tester, find.text('Library'));
}

Future<void> _tapKey(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await _waitFor(tester, finder);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _tapText(
  WidgetTester tester,
  String value, {
  bool last = false,
}) async {
  await _waitFor(tester, find.text(value));
  final finder = last ? find.text(value).last : find.text(value).first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump();
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 30),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('Timed out waiting for $finder.');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Matcher closeToDuration(Duration expected) => predicate<Duration>(
  (actual) => (actual - expected).abs() < const Duration(seconds: 2),
  'within two seconds of $expected',
);

final class _RecoveryLearningItemRepository implements LearningItemRepository {
  _RecoveryLearningItemRepository(this._delegate);

  final LearningItemRepository _delegate;
  bool _failNextLibraryCheck = true;
  bool _obscureNextCompletion = true;
  final List<String> submissionIds = [];

  @override
  Future<DiscoveryCompletion> completeDiscovery(
    DiscoverySubmission submission,
  ) async {
    submissionIds.add(submission.submissionId);
    final result = await _delegate.completeDiscovery(submission);
    if (_obscureNextCompletion) {
      _obscureNextCompletion = false;
      throw const DiscoveryFailure(
        DiscoveryFailureCode.discoveryOutcomeUnknown,
      );
    }
    return result;
  }

  @override
  Future<List<LearningItem>> findActiveBySurfaceForm(String content) {
    if (_failNextLibraryCheck) {
      _failNextLibraryCheck = false;
      throw const DiscoveryFailure(
        DiscoveryFailureCode.libraryCheckUnavailable,
      );
    }
    return _delegate.findActiveBySurfaceForm(content);
  }

  @override
  Future<DateTime?> findNextScheduled({required DateTime after}) =>
      _delegate.findNextScheduled(after: after);

  @override
  Future<List<LearningItem>> listAll() => _delegate.listAll();

  @override
  Future<List<LearningItem>> listCompletedBetween({
    required DateTime from,
    required DateTime to,
    required int limit,
  }) => _delegate.listCompletedBetween(from: from, to: to, limit: limit);

  @override
  Future<List<LearningItem>> listDue({required DateTime at, int limit = 100}) =>
      _delegate.listDue(at: at, limit: limit);

  @override
  Future<List<LearningItem>> listPage({
    required int offset,
    required int limit,
  }) => _delegate.listPage(offset: offset, limit: limit);

  @override
  Future<List<LearningItem>> listRecent({required int limit}) =>
      _delegate.listRecent(limit: limit);
}
