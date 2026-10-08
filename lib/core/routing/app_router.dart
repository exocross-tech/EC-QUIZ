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

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.asData?.value != null;
      final isAuthRoute =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';

      if (isLoading) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
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
        builder: (context, state) => const JoinContestScreen(),
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
    ],
  );
});
