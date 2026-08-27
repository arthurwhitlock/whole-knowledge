import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_auth_session_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_configuration.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_learning_item_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_review_repository.dart';
import 'package:whole_knowledge/infrastructure/dictionary/english_dictionary_api_provider.dart';
import 'package:whole_knowledge/infrastructure/local/file_capture_draft_repository.dart';

enum SupabaseBootstrapStatus {
  ready,
  notConfigured,
  invalidConfiguration,
  failed,
}

typedef SupabaseBackendInitializer = Future<AppDependencies> Function(
  SupabaseConfiguration configuration,
);

final class SupabaseBootstrap {
  SupabaseBootstrap({this.initializer = _initializeSupabase});

  final SupabaseBackendInitializer initializer;

  Future<SupabaseBootstrapResult> initialize(
    SupabaseConfigurationLoadResult configurationResult,
  ) async {
    final configuration = configurationResult.configuration;
    if (configuration == null) {
      return SupabaseBootstrapResult(
        status: configurationResult.isAbsent
            ? SupabaseBootstrapStatus.notConfigured
            : SupabaseBootstrapStatus.invalidConfiguration,
        configurationIssues: configurationResult.issues,
      );
    }

    try {
      final dependencies = await initializer(configuration);
      await dependencies.authSessions.ensureAnonymousSession();
      return SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.ready,
        dependencies: dependencies,
      );
    } on Object catch (error, stackTrace) {
      return SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.failed,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}

final class SupabaseBootstrapResult {
  SupabaseBootstrapResult({
    required this.status,
    this.dependencies,
    this.configurationIssues = const [],
    this.error,
    this.stackTrace,
  });

  final SupabaseBootstrapStatus status;
  final AppDependencies? dependencies;
  final List<SupabaseConfigurationIssue> configurationIssues;
  final Object? error;
  final StackTrace? stackTrace;
}

Future<AppDependencies> _initializeSupabase(
  SupabaseConfiguration configuration,
) async {
  final supabase = await Supabase.initialize(
    url: configuration.projectUrl.toString(),
    publishableKey: configuration.publishableKey,
  );

  return AppDependencies(
    authSessions: SupabaseAuthSessionRepository(supabase.client),
    learningItems: SupabaseLearningItemRepository(supabase.client),
    reviews: SupabaseReviewRepository(supabase.client),
    captureDrafts: FileCaptureDraftRepository(),
    lexicalProvider: EnglishDictionaryApiProvider(),
  );
}
