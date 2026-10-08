import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/firestore_quiz_repository.dart';
import '../domain/quiz.dart';

/// Real-time stream of all quizzes owned by the currently authenticated user
final userQuizzesProvider = StreamProvider<List<Quiz>>((ref) {
  final authUser = ref.watch(authStateProvider).asData?.value;
  if (authUser == null) return Stream.value([]);
  return ref.watch(quizRepositoryProvider).watchUserQuizzes(authUser.id);
});

/// Real-time stream of all publicly published quizzes
final publishedQuizzesProvider = StreamProvider<List<Quiz>>((ref) {
  return ref.watch(quizRepositoryProvider).watchPublishedQuizzes();
});


/// Controller for deleting or duplicating quizzes from the list screen
class QuizListController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> deleteQuiz(String quizId) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(quizRepositoryProvider).deleteQuiz(quizId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<Quiz?> duplicateQuiz(Quiz quiz) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).asData?.value;
      final profile = ref.read(currentUserProfileProvider).asData?.value;
      if (user == null) {
        throw Exception('User is not signed in.');
      }
      final duplicated = await ref.read(quizRepositoryProvider).duplicateQuiz(
            quiz: quiz,
            newCreatorId: user.id,
            newCreatorName: profile?.displayName ?? user.displayName ?? 'Host',
          );
      state = const AsyncValue.data(null);
      return duplicated;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final quizListControllerProvider =
    NotifierProvider<QuizListController, AsyncValue<void>>(
  QuizListController.new,
);
