import 'auth_user.dart';

abstract interface class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String course,
    required String yearLevel,
  });

  Future<void> signIn({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> sendEmailVerification();

  Future<void> reloadCurrentUser();

  Future<void> enterLocalMode();

  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseSetupRequired implements Exception {
  const FirebaseSetupRequired();

  @override
  String toString() => 'Firebase is not configured for this application.';
}
