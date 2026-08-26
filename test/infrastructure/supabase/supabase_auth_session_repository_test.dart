import 'package:flutter_test/flutter_test.dart';
import 'package:whole_knowledge/domain/auth/auth_session.dart';
import 'package:whole_knowledge/infrastructure/supabase/supabase_auth_session_repository.dart';

void main() {
  const existing = AuthSession(userId: 'existing-user');
  const refreshed = AuthSession(userId: 'refreshed-user');
  const created = AuthSession(userId: 'anonymous-user');

  test('reuses a valid restored session', () async {
    var refreshCalls = 0;
    var signInCalls = 0;
    final repository = SupabaseAuthSessionRepository.withOperations(
      () => (session: existing, isExpired: false),
      const Stream.empty(),
      () async {
        refreshCalls += 1;
        return refreshed;
      },
      () async {
        signInCalls += 1;
        return created;
      },
    );

    expect(await repository.ensureAnonymousSession(), same(existing));
    expect(refreshCalls, 0);
    expect(signInCalls, 0);
  });

  test('refreshes an expired restored session', () async {
    var signInCalls = 0;
    final repository = SupabaseAuthSessionRepository.withOperations(
      () => (session: existing, isExpired: true),
      const Stream.empty(),
      () async => refreshed,
      () async {
        signInCalls += 1;
        return created;
      },
    );

    expect(await repository.ensureAnonymousSession(), same(refreshed));
    expect(signInCalls, 0);
  });

  test('creates an anonymous session only when none is restored', () async {
    var signInCalls = 0;
    final repository = SupabaseAuthSessionRepository.withOperations(
      () => null,
      const Stream.empty(),
      () async => refreshed,
      () async {
        signInCalls += 1;
        return created;
      },
    );

    expect(await repository.ensureAnonymousSession(), same(created));
    expect(signInCalls, 1);
  });

  test('does not replace an expired identity when refresh returns null', () {
    var signInCalls = 0;
    final repository = SupabaseAuthSessionRepository.withOperations(
      () => (session: existing, isExpired: true),
      const Stream.empty(),
      () async => null,
      () async {
        signInCalls += 1;
        return created;
      },
    );

    expect(repository.ensureAnonymousSession, throwsA(isA<StateError>()));
    expect(signInCalls, 0);
  });

  test('does not replace an expired identity when refresh throws', () async {
    var signInCalls = 0;
    final repository = SupabaseAuthSessionRepository.withOperations(
      () => (session: existing, isExpired: true),
      const Stream.empty(),
      () async => throw StateError('refresh failed'),
      () async {
        signInCalls += 1;
        return created;
      },
    );

    await expectLater(
      repository.ensureAnonymousSession(),
      throwsA(isA<StateError>()),
    );
    expect(repository.currentSession, same(existing));
    expect(signInCalls, 0);
  });
}
