final class AuthSession {
  const AuthSession({required this.userId, this.expiresAt});

  final String userId;
  final DateTime? expiresAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthSession &&
            other.userId == userId &&
            other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(userId, expiresAt);
}
