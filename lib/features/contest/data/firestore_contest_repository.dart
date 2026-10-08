import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../quiz/domain/quiz.dart';
import '../../quiz/domain/quiz_question.dart';
import '../domain/contest.dart';
import '../domain/contest_answer.dart';
import '../domain/contest_participant.dart';
import 'contest_repository.dart';

final contestRepositoryProvider = Provider<ContestRepository>((ref) {
  return FirestoreContestRepository();
});

final contestStreamProvider =
    StreamProvider.family<Contest?, String>((ref, contestId) {
  return ref.watch(contestRepositoryProvider).watchContest(contestId);
});

final participantsStreamProvider =
    StreamProvider.family<List<ContestParticipant>, String>((ref, contestId) {
  return ref.watch(contestRepositoryProvider).watchParticipants(contestId);
});

class ParticipantAnswerQuery {
  final String contestId;
  final String participantId;
  final int questionIndex;

  const ParticipantAnswerQuery({
    required this.contestId,
    required this.participantId,
    required this.questionIndex,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParticipantAnswerQuery &&
          runtimeType == other.runtimeType &&
          contestId == other.contestId &&
          participantId == other.participantId &&
          questionIndex == other.questionIndex;

  @override
  int get hashCode =>
      contestId.hashCode ^ participantId.hashCode ^ questionIndex.hashCode;
}

final participantAnswerStreamProvider =
    StreamProvider.family<ContestAnswer?, ParticipantAnswerQuery>((ref, query) {
  return ref.watch(contestRepositoryProvider).watchParticipantAnswer(
        contestId: query.contestId,
        participantId: query.participantId,
        questionIndex: query.questionIndex,
      );
});

class FirestoreContestRepository implements ContestRepository {
  final FirebaseFirestore _firestore;

  FirestoreContestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _contestsCollection =>
      _firestore.collection('contests');

  @override
  Stream<Contest?> watchContest(String contestId) {
    return _contestsCollection.doc(contestId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return Contest.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Stream<List<ContestParticipant>> watchParticipants(String contestId) {
    return _contestsCollection
        .doc(contestId)
        .collection('participants')
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => ContestParticipant.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      return list;
    });
  }

  @override
  Future<List<ContestParticipant>> getParticipants(String contestId) async {
    final snapshot = await _contestsCollection
        .doc(contestId)
        .collection('participants')
        .get();

    final list = snapshot.docs
        .map((doc) => ContestParticipant.fromMap(doc.data(), doc.id))
        .toList();
    list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    return list;
  }

  @override
  Future<Contest> createContest({
    required Quiz quiz,
    required String hostId,
    required String hostName,
    String? pin,
    int maxParticipants = 20,
  }) async {
    // Generate a unique 6-character code
    String joinCode = Contest.generateJoinCode();
    int attempts = 0;
    while (attempts < 5) {
      final existing = await findContestByJoinCode(joinCode);
      if (existing == null) break;
      joinCode = Contest.generateJoinCode();
      attempts++;
    }

    final contestId = const Uuid().v4();
    final now = DateTime.now();

    final contest = Contest(
      id: contestId,
      quizId: quiz.id,
      quizTitle: quiz.title,
      quizThemeColor: quiz.themeColor,
      questionsCount: quiz.questionsCount,
      hostId: hostId,
      hostName: hostName,
      joinCode: joinCode,
      pin: pin != null && pin.trim().isNotEmpty ? pin.trim() : null,
      maxParticipants: maxParticipants,
      status: ContestStatus.lobby,
      stage: ContestStage.lobby,
      currentQuestionIndex: -1,
      kickedUserIds: const [],
      participantCount: 0,
      createdAt: now,
    );

    await _contestsCollection.doc(contestId).set(contest.toMap());
    return contest;
  }

  @override
  Future<Contest?> findContestByJoinCode(String joinCode) async {
    final cleanCode = joinCode.trim().toUpperCase();
    final query = await _contestsCollection
        .where('joinCode', isEqualTo: cleanCode)
        .where('status', isEqualTo: 'lobby')
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return Contest.fromMap(doc.data(), doc.id);
  }

  @override
  Future<void> joinContest({
    required String contestId,
    required ContestParticipant participant,
    String? pinEntered,
  }) async {
    final contestDoc = await _contestsCollection.doc(contestId).get();
    if (!contestDoc.exists || contestDoc.data() == null) {
      throw Exception('Contest does not exist.');
    }

    final contest = Contest.fromMap(contestDoc.data()!, contestDoc.id);

    if (contest.status != ContestStatus.lobby) {
      throw Exception('This contest has already started or ended.');
    }

    if (contest.kickedUserIds.contains(participant.id)) {
      throw Exception('You were removed from this contest lobby by the host.');
    }

    if (contest.hasPin) {
      if (pinEntered == null || pinEntered.trim() != contest.pin) {
        throw Exception('Incorrect contest PIN. Please check with the host.');
      }
    }

    if (contest.participantCount >= contest.maxParticipants) {
      throw Exception(
        'Lobby is full! Max players (${contest.maxParticipants}) reached.',
      );
    }

    // Write participant doc
    final participantRef = _contestsCollection
        .doc(contestId)
        .collection('participants')
        .doc(participant.id);

    final isAlreadyJoined = (await participantRef.get()).exists;

    await participantRef.set(participant.toMap(), SetOptions(merge: true));

    if (!isAlreadyJoined) {
      await _contestsCollection.doc(contestId).update({
        'participantCount': FieldValue.increment(1),
      });
    }
  }

  @override
  Future<void> kickParticipant({
    required String contestId,
    required String participantId,
  }) async {
    await _contestsCollection.doc(contestId).update({
      'kickedUserIds': FieldValue.arrayUnion([participantId]),
      'participantCount': FieldValue.increment(-1),
    });

    await _contestsCollection
        .doc(contestId)
        .collection('participants')
        .doc(participantId)
        .delete();
  }

  @override
  Future<void> leaveContest({
    required String contestId,
    required String participantId,
  }) async {
    final participantRef = _contestsCollection
        .doc(contestId)
        .collection('participants')
        .doc(participantId);

    final exists = (await participantRef.get()).exists;
    if (exists) {
      await participantRef.delete();
      await _contestsCollection.doc(contestId).update({
        'participantCount': FieldValue.increment(-1),
      });
    }
  }

  @override
  Future<void> updateContestStatus({
    required String contestId,
    required ContestStatus status,
    String? endedReason,
  }) async {
    final Map<String, dynamic> updateData = {
      'status': status.toDbValue,
    };

    if (endedReason != null) {
      updateData['endedReason'] = endedReason;
    }

    if (status == ContestStatus.inProgress) {
      updateData['startedAt'] = FieldValue.serverTimestamp();
      updateData['currentQuestionIndex'] = 0;
      updateData['stage'] = ContestStage.questionActive.name;
    } else if (status == ContestStatus.ended) {
      updateData['endedAt'] = FieldValue.serverTimestamp();
      updateData['stage'] = ContestStage.ended.name;
    }

    await _contestsCollection.doc(contestId).update(updateData);
  }

  @override
  Future<void> endContest(String contestId, {String? endedReason}) async {
    await updateContestStatus(
      contestId: contestId,
      status: ContestStatus.ended,
      endedReason: endedReason,
    );
  }

  // --- LIVE GAMEPLAY IMPLEMENTATION ---

  @override
  Future<void> startLiveGame({
    required String contestId,
    required QuizQuestion firstQuestion,
  }) async {
    final activeQ = ActiveQuestion(
      text: firstQuestion.text,
      type: firstQuestion.type,
      options: (firstQuestion.type == QuestionType.shortText ||
              firstQuestion.type == QuestionType.numeric)
          ? const []
          : firstQuestion.options,
      timeLimitSeconds: firstQuestion.timeLimitSeconds,
      basePoints: firstQuestion.basePoints,
      imagesBase64: firstQuestion.imagesBase64,
      explanation: null,
      correctAnswers: const [], // anti-cheat: empty during question
    );

    await _contestsCollection.doc(contestId).update({
      'status': ContestStatus.inProgress.toDbValue,
      'stage': ContestStage.questionActive.name,
      'startedAt': FieldValue.serverTimestamp(),
      'currentQuestionIndex': 0,
      'questionOpenedAt': FieldValue.serverTimestamp(),
      'activeQuestion': activeQ.toMap(),
      'answerDistribution': <String, int>{},
      'answersSubmittedCount': 0,
      'isPaused': false,
    });
  }

  @override
  Future<void> submitAnswer({
    required String contestId,
    required String participantId,
    required String participantName,
    required int questionIndex,
    required List<dynamic> selectedAnswers,
  }) async {
    final answerRef = _contestsCollection
        .doc(contestId)
        .collection('answers')
        .doc('${participantId}_$questionIndex');

    final existing = await answerRef.get();
    if (existing.exists) return; // Prevent double submission

    await answerRef.set({
      'participantId': participantId,
      'participantName': participantName,
      'questionIndex': questionIndex,
      'selectedAnswers': selectedAnswers,
      'submittedAt': FieldValue.serverTimestamp(),
      'pointsAwarded': 0,
      'isCorrect': false,
      'responseTimeSeconds': 0.0,
    });

    await _contestsCollection.doc(contestId).update({
      'answersSubmittedCount': FieldValue.increment(1),
    });
  }

  @override
  Stream<ContestAnswer?> watchParticipantAnswer({
    required String contestId,
    required String participantId,
    required int questionIndex,
  }) {
    return _contestsCollection
        .doc(contestId)
        .collection('answers')
        .doc('${participantId}_$questionIndex')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return ContestAnswer.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<List<ContestAnswer>> getQuestionAnswers({
    required String contestId,
    required int questionIndex,
  }) async {
    final snapshot = await _contestsCollection
        .doc(contestId)
        .collection('answers')
        .where('questionIndex', isEqualTo: questionIndex)
        .get();

    return snapshot.docs
        .map((doc) => ContestAnswer.fromMap(doc.data(), doc.id))
        .toList();
  }

  @override
  Future<void> revealAnswers({
    required String contestId,
    required int questionIndex,
    required List<int> correctAnswers,
    List<String>? options,
    String? explanation,
    required Map<String, int> distribution,
    required Map<String, int> participantPoints,
    required Map<String, bool> participantCorrectness,
    required Map<String, int> participantStreaks,
  }) async {
    final batch = _firestore.batch();

    // 1. Update participant scores and streaks
    for (final entry in participantPoints.entries) {
      final pid = entry.key;
      final pts = entry.value;
      final isCorrect = participantCorrectness[pid] ?? false;
      final streak = participantStreaks[pid] ?? 0;

      final pRef = _contestsCollection
          .doc(contestId)
          .collection('participants')
          .doc(pid);

      batch.update(pRef, {
        'totalScore': FieldValue.increment(pts),
        'lastPointsEarned': pts,
        'streak': streak,
        'isCorrectLastAnswer': isCorrect,
      });

      // Update answer record
      final aRef = _contestsCollection
          .doc(contestId)
          .collection('answers')
          .doc('${pid}_$questionIndex');

      batch.update(aRef, {
        'pointsAwarded': pts,
        'isCorrect': isCorrect,
      });
    }

    // 2. Update contest doc to answerReveal
    final contestRef = _contestsCollection.doc(contestId);
    final Map<String, dynamic> contestUpdate = {
      'stage': ContestStage.answerReveal.name,
      'answerDistribution': distribution,
      'activeQuestion.correctAnswers': correctAnswers,
    };
    if (options != null) {
      contestUpdate['activeQuestion.options'] = options;
    }
    if (explanation != null && explanation.trim().isNotEmpty) {
      contestUpdate['activeQuestion.explanation'] = explanation;
    }
    batch.update(contestRef, contestUpdate);

    await batch.commit();
  }

  @override
  Future<void> showLeaderboard(String contestId) async {
    await _contestsCollection.doc(contestId).update({
      'stage': ContestStage.leaderboard.name,
    });
  }

  @override
  Future<void> nextQuestion({
    required String contestId,
    required int nextIndex,
    required QuizQuestion nextQuestion,
  }) async {
    final activeQ = ActiveQuestion(
      text: nextQuestion.text,
      type: nextQuestion.type,
      options: (nextQuestion.type == QuestionType.shortText ||
              nextQuestion.type == QuestionType.numeric)
          ? const []
          : nextQuestion.options,
      timeLimitSeconds: nextQuestion.timeLimitSeconds,
      basePoints: nextQuestion.basePoints,
      imagesBase64: nextQuestion.imagesBase64,
      explanation: null,
      correctAnswers: const [], // anti-cheat: empty during question
    );

    await _contestsCollection.doc(contestId).update({
      'stage': ContestStage.questionActive.name,
      'currentQuestionIndex': nextIndex,
      'questionOpenedAt': FieldValue.serverTimestamp(),
      'activeQuestion': activeQ.toMap(),
      'answerDistribution': <String, int>{},
      'answersSubmittedCount': 0,
      'isPaused': false,
    });
  }

  @override
  Future<void> showPodium(String contestId) async {
    await _contestsCollection.doc(contestId).update({
      'stage': ContestStage.podium.name,
      'status': ContestStatus.ended.toDbValue,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> setContestPaused({
    required String contestId,
    required bool isPaused,
  }) async {
    await _contestsCollection.doc(contestId).update({
      'isPaused': isPaused,
    });
  }
}
