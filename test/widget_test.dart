import 'dart:async';

import 'package:flash_ed/app.dart';
import 'package:flash_ed/features/authentication/domain/auth_repository.dart';
import 'package:flash_ed/features/authentication/domain/auth_user.dart';
import 'package:flash_ed/features/authentication/presentation/auth_providers.dart';
import 'package:flash_ed/features/flashcards/data/flashcard_repository.dart';
import 'package:flash_ed/features/flashcards/presentation/flashcard_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('registration creates account and requires email verification', (
    tester,
  ) async {
    final auth = _MemoryAuthRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const FlashEdApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('register-name')), 'A Student');
    await tester.enterText(
      find.byKey(const Key('register-email')),
      'student@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('register-course')),
      'Computer Science',
    );
    await tester.ensureVisible(find.byKey(const Key('register-year')));
    await tester.tap(find.byKey(const Key('register-year')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2nd Year').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('register-password')),
      'learning123',
    );
    await tester.enterText(
      find.byKey(const Key('register-confirm-password')),
      'learning123',
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account').last);
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(auth.registeredEmail, 'student@example.com');
    expect(auth.registeredCourse, 'Computer Science');
    expect(auth.registeredYear, '2nd Year');
  });

  testWidgets('login opens the dashboard after successful authentication', (
    tester,
  ) async {
    final auth = _MemoryAuthRepository();
    addTearDown(auth.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(auth)],
        child: const FlashEdApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'student@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'learning123',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.text('Hi, Student'), findsOneWidget);
  });

  testWidgets('signed-out users can open registration and see validation', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FlashEdApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('register-name')), findsOneWidget);
    expect(find.byKey(const Key('register-email')), findsOneWidget);
    expect(find.byKey(const Key('register-password')), findsOneWidget);

    await tester.ensureVisible(find.text('Create account').first);
    await tester.tap(find.text('Create account').first);
    await tester.pumpAndSettle();

    expect(find.text('Enter your full name.'), findsOneWidget);
  });

  testWidgets('password reset route validates the email field', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FlashEdApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset your password'), findsOneWidget);
    await tester.tap(find.text('Send reset link'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address.'), findsOneWidget);
  });

  testWidgets('login explains when Firebase configuration is missing', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: FlashEdApp()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login-email')),
      'student@example.com',
    );
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'learning123',
    );
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Connect a Firebase project'), findsOneWidget);
  });

  testWidgets('guest mode opens the app and returns to sign in on exit', (
    tester,
  ) async {
    final repository = FlashcardRepository(_MemoryFlashcardPreferences());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [flashcardRepositoryProvider.overrideWithValue(repository)],
        child: const FlashEdApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Continue without Firebase'));
    await tester.tap(find.text('Continue without Firebase'));
    await tester.pumpAndSettle();
    expect(find.text('Hi, Guest'), findsOneWidget);

    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();
    expect(find.text('Local guest mode'), findsOneWidget);
    await tester.tap(find.text('Exit local mode'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
  });

  testWidgets('creates and studies a set with real local persistence', (
    tester,
  ) async {
    final repository = FlashcardRepository(_MemoryFlashcardPreferences());
    const user = AuthUser(
      id: 'student-1',
      email: 'student@example.com',
      emailVerified: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith((ref) => Stream.value(user)),
          flashcardRepositoryProvider.overrideWithValue(repository),
        ],
        child: const FlashEdApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Flashcards').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create a set'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('set-title')), 'Networking');
    await tester.enterText(find.byKey(const Key('set-subject')), 'Computing');
    await tester.enterText(
      find.byKey(const Key('card-front-0')),
      'What is DNS?',
    );
    await tester.enterText(
      find.byKey(const Key('card-back-0')),
      'A system that translates domain names.',
    );
    await tester.tap(find.text('Add another card'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('card-front-1')),
      'What is an IP address?',
    );
    await tester.enterText(
      find.byKey(const Key('card-back-1')),
      'A logical address for a device.',
    );
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    expect(find.text('Networking'), findsOneWidget);
    final sets = await repository.getSets(user.id);
    expect(sets, hasLength(1));
    expect(sets.single.cards, hasLength(2));

    await tester.tap(find.text('Networking').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Study cards'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    expect(find.text('A system that translates domain names.'), findsOneWidget);
    await tester.tap(find.text('I knew it'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Review again'));
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
    final activities = await repository.getActivities(user.id);
    expect(activities, hasLength(1));
    expect(activities.single.kind, 'study');
    expect(activities.single.total, 2);
    expect(activities.single.correct, 1);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take a quiz'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start quiz'));
    await tester.pumpAndSettle();

    for (var index = 0; index < 2; index++) {
      final answer = find.text('What is DNS?').evaluate().isNotEmpty
          ? 'A system that translates domain names.'
          : 'A logical address for a device.';
      await tester.tap(find.text(answer).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(index == 1 ? 'Finish quiz' : 'Next question'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Quiz complete: 100%'), findsOneWidget);
    final quiz = (await repository.getActivities(user.id))
        .singleWhere((activity) => activity.kind == 'quiz');
    expect(quiz.correct, 2);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Progress').last);
    await tester.pumpAndSettle();

    expect(find.text('Average quiz score'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
  });
}

class _MemoryFlashcardPreferences implements FlashcardPreferences {
  final Map<String, String> _values = {};

  @override
  Future<String?> getString(String key) async => _values[key];

  @override
  Future<void> setString(String key, String value) async {
    _values[key] = value;
  }
}

class _MemoryAuthRepository implements AuthRepository {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _user;
  String? registeredEmail;
  String? registeredCourse;
  String? registeredYear;

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
  }) async {
    registeredEmail = email;
    registeredCourse = course;
    registeredYear = yearLevel;
    _user = AuthUser(
      id: 'student-1',
      email: email,
      displayName: fullName,
      emailVerified: false,
    );
    _controller.add(_user);
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    _user = AuthUser(
      id: 'student-1',
      email: email,
      displayName: 'Student',
      emailVerified: true,
    );
    _controller.add(_user);
  }

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> enterLocalMode() async {}

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadCurrentUser() async {
    _user = AuthUser(
      id: 'student-1',
      email: _user!.email,
      displayName: _user!.displayName,
      emailVerified: true,
    );
    _controller.add(_user);
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  Future<void> dispose() => _controller.close();
}
