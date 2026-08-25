import 'package:whole_knowledge/domain/auth/auth_session.dart';

abstract interface class AuthSessionRepository {
  AuthSession? get currentSession;

  Stream<AuthSession?> get sessionChanges;
}
