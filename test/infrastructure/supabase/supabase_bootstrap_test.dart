import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/application/auth/auth_session_repository.dart';
import 'package:whole_knowledge/domain/auth/auth_session.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_bootstrap.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_configuration.dart';

void main() {
  group('SupabaseBootstrap', () {
    test('skips initialization when configuration is absent', () async {
      var initializerCalled = false;
      final bootstrap = SupabaseBootstrap(
        initializer: (configuration) async {
          initializerCalled = true;
          return const _FakeAuthSessionRepository();
        },
      );

      final result = await bootstrap.initialize(
        SupabaseConfiguration.load(projectUrl: '', publishableKey: ''),
      );

      expect(result.status, SupabaseBootstrapStatus.notConfigured);
      expect(result.authSessions, isNull);
      expect(initializerCalled, isFalse);
    });

    test('rejects partial configuration before initialization', () async {
      var initializerCalled = false;
      final bootstrap = SupabaseBootstrap(
        initializer: (configuration) async {
          initializerCalled = true;
          return const _FakeAuthSessionRepository();
        },
      );

      final result = await bootstrap.initialize(
        SupabaseConfiguration.load(projectUrl: 'https://project.supabase.co'),
      );

      expect(result.status, SupabaseBootstrapStatus.invalidConfiguration);
      expect(initializerCalled, isFalse);
    });

    test(
      'returns repository contract after successful initialization',
      () async {
        const repository = _FakeAuthSessionRepository();
        final bootstrap = SupabaseBootstrap(
          initializer: (configuration) async => repository,
        );

        final result = await bootstrap.initialize(_configuredResult());

        expect(result.status, SupabaseBootstrapStatus.ready);
        expect(result.authSessions, same(repository));
        expect(result.error, isNull);
      },
    );

    test('contains initializer failures instead of crashing startup', () async {
      final bootstrap = SupabaseBootstrap(
        initializer: (configuration) async => throw StateError('unavailable'),
      );

      final result = await bootstrap.initialize(_configuredResult());

      expect(result.status, SupabaseBootstrapStatus.failed);
      expect(result.authSessions, isNull);
      expect(result.error, isA<StateError>());
      expect(result.stackTrace, isNotNull);
    });
  });
}

SupabaseConfigurationLoadResult _configuredResult() {
  return SupabaseConfiguration.load(
    projectUrl: 'https://project.supabase.co',
    publishableKey: 'publishable-key',
  );
}

final class _FakeAuthSessionRepository implements AuthSessionRepository {
  const _FakeAuthSessionRepository();

  @override
  AuthSession? get currentSession => null;

  @override
  Stream<AuthSession?> get sessionChanges => const Stream.empty();
}
