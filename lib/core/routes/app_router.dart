import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/auth_providers.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/authentication/presentation/reset_password_screen.dart';
import '../../features/authentication/presentation/verify_email_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/flashcards/presentation/flashcard_editor_screen.dart';
import '../../features/flashcards/presentation/flashcard_set_screen.dart';
import '../../features/flashcards/presentation/flashcards_screen.dart';
import '../../features/flashcards/presentation/quiz_screen.dart';
import '../../features/flashcards/presentation/study_screen.dart';
import '../../features/materials/presentation/materials_screen.dart';
import '../../features/progress/presentation/progress_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  late final GoRouter router;
  ref.listen(authStateProvider, (previous, next) => router.refresh());
  router = GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      if (!auth.hasValue) return null;
      final user = auth.value;
      final isSignedIn = user != null;
      final isAuthenticationRoute = {
        '/login',
        '/register',
        '/reset-password',
      }.contains(state.matchedLocation);
      final isVerificationRoute = state.matchedLocation == '/verify-email';
      if (!isSignedIn && !isAuthenticationRoute && !isVerificationRoute) {
        return '/login';
      }
      if (isSignedIn && !user.emailVerified && !isVerificationRoute) {
        return '/verify-email';
      }
      if (isSignedIn &&
          user.emailVerified &&
          (isAuthenticationRoute || isVerificationRoute)) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => const VerifyEmailScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/materials',
                builder: (context, state) => const MaterialsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/flashcards',
                builder: (context, state) => const FlashcardsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/flashcards/create',
        builder: (context, state) => const FlashcardEditorScreen(),
      ),
      GoRoute(
        path: '/flashcards/:setId/edit',
        builder: (context, state) =>
            FlashcardEditorScreen(setId: state.pathParameters['setId']),
      ),
      GoRoute(
        path: '/flashcards/:setId/study',
        builder: (context, state) =>
            StudyScreen(setId: state.pathParameters['setId']!),
      ),
      GoRoute(
        path: '/flashcards/:setId/quiz',
        builder: (context, state) =>
            QuizScreen(setId: state.pathParameters['setId']!),
      ),
      GoRoute(
        path: '/flashcards/:setId',
        builder: (context, state) =>
            FlashcardSetScreen(setId: state.pathParameters['setId']!),
      ),
    ],
  );
  return router;
});
