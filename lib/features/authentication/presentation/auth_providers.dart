import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_runtime.dart';
import '../data/firebase_auth_repository.dart';
import '../domain/auth_repository.dart';
import '../domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!FirebaseRuntime.isConfigured || Firebase.apps.isEmpty) {
    return LocalAuthRepository();
  }
  return FirebaseAuthRepository(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );
});

final authStateProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges(),
);

final localModeAvailableProvider = Provider<bool>(
  (ref) => ref.watch(authRepositoryProvider) is LocalAuthRepository,
);

class LocalAuthRepository implements AuthRepository {
  AuthUser? _user;
  final _controller = StreamController<AuthUser?>.broadcast();

  @override
  Stream<AuthUser?> authStateChanges() async* {
    yield _user;
    yield* _controller.stream;
  }

  @override
  Future<void> register({
    required String fullName,
    required String email,
    required String password,
    required String course,
    required String yearLevel,
  }) => throw const FirebaseSetupRequired();

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw const FirebaseSetupRequired();

  @override
  Future<void> sendPasswordReset(String email) =>
      throw const FirebaseSetupRequired();

  @override
  Future<void> sendEmailVerification() => throw const FirebaseSetupRequired();

  @override
  Future<void> reloadCurrentUser() => throw const FirebaseSetupRequired();

  @override
  Future<void> enterLocalMode() async {
    _user = const AuthUser(
      id: 'local-guest',
      email: '',
      displayName: 'Guest',
      emailVerified: true,
      isGuest: true,
    );
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  void dispose() => _controller.close();
}
