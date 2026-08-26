import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/auth/auth_session_repository.dart';
import 'package:whole_knowledge/domain/auth/auth_session.dart';

typedef SupabaseSessionSnapshot = ({AuthSession session, bool isExpired});
typedef SupabaseSessionReader = SupabaseSessionSnapshot? Function();
typedef SupabaseSessionOperation = Future<AuthSession?> Function();

final class SupabaseAuthSessionRepository implements AuthSessionRepository {
  SupabaseAuthSessionRepository(SupabaseClient client)
    : this.withOperations(
        () => _toSnapshot(client.auth.currentSession),
        client.auth.onAuthStateChange
            .map((state) => _toDomain(state.session))
            .distinct(),
        () async {
          return _toDomain((await client.auth.refreshSession()).session);
        },
        () async {
          return _toDomain((await client.auth.signInAnonymously()).session);
        },
      );

  const SupabaseAuthSessionRepository.withOperations(
    this._readSession,
    this._sessionChanges,
    this._refreshSession,
    this._signInAnonymously,
  );

  final SupabaseSessionReader _readSession;
  final Stream<AuthSession?> _sessionChanges;
  final SupabaseSessionOperation _refreshSession;
  final SupabaseSessionOperation _signInAnonymously;

  @override
  AuthSession? get currentSession => _readSession()?.session;

  @override
  Stream<AuthSession?> get sessionChanges => _sessionChanges;

  @override
  Future<AuthSession> ensureAnonymousSession() async {
    final existing = _readSession();
    if (existing != null) {
      if (!existing.isExpired) {
        return existing.session;
      }

      final refreshed = await _refreshSession();
      if (refreshed == null) {
        throw StateError('Session refresh did not return a session.');
      }
      return refreshed;
    }

    final session = await _signInAnonymously();
    if (session == null) {
      throw StateError('Anonymous sign-in did not return a session.');
    }
    return session;
  }

  static SupabaseSessionSnapshot? _toSnapshot(Session? session) {
    final domainSession = _toDomain(session);
    if (session == null || domainSession == null) {
      return null;
    }
    return (session: domainSession, isExpired: session.isExpired);
  }

  static AuthSession? _toDomain(Session? session) {
    if (session == null) {
      return null;
    }

    final expiresAt = session.expiresAt;
    return AuthSession(
      userId: session.user.id,
      expiresAt: expiresAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              expiresAt * Duration.millisecondsPerSecond,
              isUtc: true,
            ),
    );
  }
}
