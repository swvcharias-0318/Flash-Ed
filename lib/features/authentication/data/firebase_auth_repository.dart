import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  @override
  Stream<AuthUser?> authStateChanges() => _auth.idTokenChanges().map(_mapUser);

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String course,
    required String yearLevel,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(fullName.trim());
      await credential.user?.reload();
      final user = credential.user;
      if (user == null) {
        throw const AuthFailure('Account creation did not return a user.');
      }
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': fullName.trim(),
        'email': email.trim(),
        'course': course.trim(),
        'yearLevel': yearLevel.trim(),
        'profileImage': null,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error.code));
    } on FirebaseException {
      throw AuthFailure(
        'Your account was created, but the profile could not be saved. '
        'Check the Firestore rules and try signing in again.',
      );
    }
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error.code));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (error) {
      throw AuthFailure(_messageFor(error.code));
    }
  }

  @override
  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
    await _auth.currentUser?.getIdToken(true);
  }

  @override
  Future<void> enterLocalMode() => throw const FirebaseSetupRequired();

  @override
  Future<void> signOut() => _auth.signOut();

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      id: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      isGuest: false,
      displayName: user.displayName,
    );
  }

  String _messageFor(String code) => switch (code) {
    'email-already-in-use' => 'An account already exists for this email.',
    'invalid-email' => 'Enter a valid email address.',
    'weak-password' => 'Choose a stronger password.',
    'user-disabled' => 'This account has been disabled.',
    'user-not-found' ||
    'wrong-password' ||
    'invalid-credential' => 'Email or password is incorrect.',
    'too-many-requests' => 'Too many attempts. Please wait and try again.',
    'network-request-failed' =>
      'Could not connect. Check your internet connection.',
    _ => 'Authentication failed. Please try again.',
  };
}
