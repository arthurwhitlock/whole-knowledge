import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/app/app_dependencies.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_bootstrap.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_configuration.dart';

import '../../support/fakes.dart';

void main() {
  group('SupabaseBootstrap', () {
    test('skips initialization when configuration is absent', () async {
      var initializerCalled = false;
      final bootstrap = SupabaseBootstrap(
        initializer: (configuration) async {
          initializerCalled = true;
          return fakeDependencies();
        },
      );

      final result = await bootstrap.initialize(
        SupabaseConfiguration.load(projectUrl: '', publishableKey: ''),
      );

      expect(result.status, SupabaseBootstrapStatus.notConfigured);
      expect(result.dependencies, isNull);
      expect(initializerCalled, isFalse);
    });

    test('rejects partial configuration before initialization', () async {
      var initializerCalled = false;
      final bootstrap = SupabaseBootstrap(
        initializer: (configuration) async {
          initializerCalled = true;
          return fakeDependencies();
        },
      );

      final result = await bootstrap.initialize(
        SupabaseConfiguration.load(projectUrl: 'https://project.supabase.co'),
      );

      expect(result.status, SupabaseBootstrapStatus.invalidConfiguration);
      expect(initializerCalled, isFalse);
    });

    test('ensures an anonymous session before becoming ready', () async {
      final auth = FakeAuthSessionRepository();
      final original = fakeDependencies();
      final dependencies = AppDependencies(
        authSessions: auth,
        learningItems: original.learningItems,
        reviews: original.reviews,
      );
      final bootstrap = SupabaseBootstrap(
        initializer: (configuration) async => dependencies,
      );

      final result = await bootstrap.initialize(_configuredResult());

      expect(result.status, SupabaseBootstrapStatus.ready);
      expect(result.dependencies, same(dependencies));
      expect(auth.ensureCalls, 1);
      expect(result.error, isNull);
    });

    test('contains anonymous auth failures during startup', () async {
      final auth = FakeAuthSessionRepository(shouldFail: true);
      final original = fakeDependencies();
      final dependencies = AppDependencies(
        authSessions: auth,
        learningItems: original.learningItems,
        reviews: original.reviews,
      );
      final bootstrap = SupabaseBootstrap(
        initializer: (configuration) async => dependencies,
      );

      final result = await bootstrap.initialize(_configuredResult());

      expect(result.status, SupabaseBootstrapStatus.failed);
      expect(result.dependencies, isNull);
      expect(auth.ensureCalls, 1);
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
