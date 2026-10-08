import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../domain/quiz.dart';
import 'quiz_repository.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  return FirestoreQuizRepository();
});

class FirestoreQuizRepository implements QuizRepository {
  final FirebaseFirestore _firestore;

  FirestoreQuizRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _quizzesCollection =>
      _firestore.collection('quizzes');

  @override
  Stream<List<Quiz>> watchUserQuizzes(String userId) {
    // We sort in-memory to prevent requiring composite indexes in the Firebase Spark Console
    return _quizzesCollection
        .where('creatorId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Quiz.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  @override
  Stream<List<Quiz>> watchPublishedQuizzes() {
    return _quizzesCollection
        .where('isDraft', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => Quiz.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  @override
  Future<Quiz?> getQuiz(String quizId) async {
    final doc = await _quizzesCollection.doc(quizId).get();
    if (!doc.exists || doc.data() == null) {
      return null;
    }
    return Quiz.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> saveQuiz(Quiz quiz) async {
    // 1 MB Document size limit check
    if (!quiz.isUnderDocLimit) {
      final kb = (quiz.estimatedSizeBytes / 1024).toStringAsFixed(1);
      final maxKb = (AppConstants.maxDocSizeBytes / 1024).toStringAsFixed(0);
      throw Exception(
        'Quiz document size ($kb KB) exceeds the maximum allowed limit of $maxKb KB (1 MB Firestore limit). Please delete or compress some images before saving.',
      );
    }

    final updatedQuiz = quiz.copyWith(updatedAt: DateTime.now());
    await _quizzesCollection.doc(quiz.id).set(
          updatedQuiz.toMap(),
          SetOptions(merge: true),
        );
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    await _quizzesCollection.doc(quizId).delete();
  }

  @override
  Future<Quiz> duplicateQuiz({
    required Quiz quiz,
    required String newCreatorId,
    required String newCreatorName,
  }) async {
    final duplicated = quiz.duplicate(
      newCreatorId: newCreatorId,
      newCreatorName: newCreatorName,
    );
    await saveQuiz(duplicated);
    return duplicated;
  }
}
