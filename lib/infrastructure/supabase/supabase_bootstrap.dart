import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/auth/auth_session_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_auth_session_repository.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_configuration.dart';

enum SupabaseBootstrapStatus {
  ready,
  notConfigured,
  invalidConfiguration,
  failed,
}

typedef SupabaseBackendInitializer = Future<AuthSessionRepository> Function(
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
      final authSessions = await initializer(configuration);
      return SupabaseBootstrapResult(
        status: SupabaseBootstrapStatus.ready,
        authSessions: authSessions,
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
    this.authSessions,
    this.configurationIssues = const [],
    this.error,
    this.stackTrace,
  });

  final SupabaseBootstrapStatus status;
  final AuthSessionRepository? authSessions;
  final List<SupabaseConfigurationIssue> configurationIssues;
  final Object? error;
  final StackTrace? stackTrace;
}

Future<AuthSessionRepository> _initializeSupabase(
  SupabaseConfiguration configuration,
) async {
  final supabase = await Supabase.initialize(
    url: configuration.projectUrl.toString(),
    publishableKey: configuration.publishableKey,
  );

  return SupabaseAuthSessionRepository(supabase.client);
}
