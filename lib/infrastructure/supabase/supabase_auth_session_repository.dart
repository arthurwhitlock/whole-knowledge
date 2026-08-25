import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:whole_knowledge/application/auth/auth_session_repository.dart';
import 'package:whole_knowledge/domain/auth/auth_session.dart';

final class SupabaseAuthSessionRepository implements AuthSessionRepository {
  const SupabaseAuthSessionRepository(this._client);

  final SupabaseClient _client;

  @override
  AuthSession? get currentSession => _toDomain(_client.auth.currentSession);

  @override
  Stream<AuthSession?> get sessionChanges {
    return _client.auth.onAuthStateChange
        .map((state) => _toDomain(state.session))
        .distinct();
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
