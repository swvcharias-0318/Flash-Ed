class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.emailVerified,
    this.isGuest = false,
    this.displayName,
  });

  final String id;
  final String email;
  final bool emailVerified;
  final bool isGuest;
  final String? displayName;
}
