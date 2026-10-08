import '../domain/quiz.dart';

abstract class QuizRepository {
  /// Real-time stream of all quizzes authored by [userId] (both drafts and published)
  Stream<List<Quiz>> watchUserQuizzes(String userId);

  /// Real-time stream of published quizzes available for hosting
  Stream<List<Quiz>> watchPublishedQuizzes();

  /// Fetches a single quiz by its document ID
  Future<Quiz?> getQuiz(String quizId);

  /// Saves or updates a quiz in Firestore (enforcing the 1 MB document quota)
  Future<void> saveQuiz(Quiz quiz);

  /// Deletes a quiz document from Firestore
  Future<void> deleteQuiz(String quizId);

  /// Clones a quiz and stores the duplicate in Firestore
  Future<Quiz> duplicateQuiz({
    required Quiz quiz,
    required String newCreatorId,
    required String newCreatorName,
  });
}
