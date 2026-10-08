import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/quiz/presentation/quiz_editor_screen.dart';
import '../../features/quiz/presentation/quiz_list_screen.dart';
import '../../features/contest/presentation/host_lobby_screen.dart';
import '../../features/contest/presentation/join_contest_screen.dart';
import '../../features/contest/presentation/player_lobby_screen.dart';
import '../../features/practice/presentation/practice_quiz_select_screen.dart';
import '../../features/practice/presentation/solo_game_screen.dart';
import '../services/sound_service.dart';

/// Bridges Riverpod reactive auth/guest state changes into GoRouter's refresh mechanism
/// without destroying and re-instantiating the GoRouter instance.
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, _) => notifyListeners());
    _ref.listen(guestUserProvider, (_, _) => notifyListeners());
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  final notifier = RouterNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,
    initialLocation: '/home',
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final guestUser = ref.read(guestUserProvider);

      final isLoading = authState.isLoading;
      final firebaseUser = authState.asData?.value;
      final isAnonymousUser =
          (firebaseUser != null && firebaseUser.isAnonymous) || (guestUser != null);
      final isRegisteredUser = firebaseUser != null && !firebaseUser.isAnonymous;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isContestRoute =
          state.matchedLocation.startsWith('/contests/join') ||
          state.matchedLocation.startsWith('/contests/play');

      // Context-aware BGM suppression: Turn off BGM during live contests or Quiz Studio/Builder
      final isContestOrQuizRoute = state.matchedLocation.startsWith('/contests') ||
          state.matchedLocation.startsWith('/quiz');
      ref.read(soundServiceProvider).setBgmSuppressed(isContestOrQuizRoute);

      if (isLoading) return null;

      // 1. Anonymous Quick-Play User:
      // STRICTLY restricted to /contests/join and /contests/play/:contestId.
      // NEVER allowed on /home, /profile, /quizzes, etc.
      if (isAnonymousUser && !isRegisteredUser) {
        if (!isContestRoute) {
          return '/login';
        }
        return null;
      }

      // 2. Unauthenticated User (not logged in at all):
      if (!isRegisteredUser) {
        if (!isAuthRoute && !isContestRoute) {
          return '/login';
        }
        return null;
      }

      // 3. Registered User:
      if (isRegisteredUser && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/quizzes',
        builder: (context, state) => const QuizListScreen(),
      ),
      GoRoute(
        path: '/quiz/new',
        builder: (context, state) => const QuizEditorScreen(),
      ),
      GoRoute(
        path: '/quiz/edit/:quizId',
        builder: (context, state) {
          final quizId = state.pathParameters['quizId'];
          return QuizEditorScreen(quizId: quizId);
        },
      ),
      GoRoute(
        path: '/contests/join',
        builder: (context, state) {
          final code = state.uri.queryParameters['code'];
          return JoinContestScreen(initialCode: code);
        },
      ),
      GoRoute(
        path: '/contests/host/:contestId',
        builder: (context, state) {
          final contestId = state.pathParameters['contestId'] ?? '';
          return HostLobbyScreen(contestId: contestId);
        },
      ),
      GoRoute(
        path: '/contests/play/:contestId',
        builder: (context, state) {
          final contestId = state.pathParameters['contestId'] ?? '';
          return PlayerLobbyScreen(contestId: contestId);
        },
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) => const PracticeQuizSelectScreen(),
      ),
      GoRoute(
        path: '/practice/:quizId',
        builder: (context, state) {
          final quizId = state.pathParameters['quizId'] ?? '';
          return SoloGameScreen(quizId: quizId);
        },
      ),
    ],
  );
});

