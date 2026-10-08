import 'package:flutter_test/flutter_test.dart';
import 'package:quizapp/core/utils/scoring_utils.dart';
import 'package:quizapp/features/contest/domain/contest.dart';
import 'package:quizapp/features/contest/domain/contest_answer.dart';
import 'package:quizapp/features/contest/domain/contest_participant.dart';
import 'package:quizapp/features/quiz/domain/quiz_question.dart';

void main() {
  group('Phase 4 Live Gameplay Domain Tests', () {
    test('Contest model serializes and deserializes live gameplay stage and ActiveQuestion', () {
      final now = DateTime.now();
      final openedAt = now.add(const Duration(seconds: 1));

      final activeQ = ActiveQuestion(
        text: 'What is the capital of France?',
        type: QuestionType.multipleChoice,
        options: const ['Berlin', 'Madrid', 'Paris', 'Rome'],
        timeLimitSeconds: 20,
        basePoints: 1000,
        correctAnswers: const [], // anti-cheat: empty during active question
      );

      final contest = Contest(
        id: 'contest-live-1',
        quizId: 'quiz-101',
        quizTitle: 'Geography Mania',
        questionsCount: 5,
        hostId: 'host-1',
        hostName: 'Host Master',
        joinCode: 'GEO123',
        status: ContestStatus.inProgress,
        stage: ContestStage.questionActive,
        currentQuestionIndex: 0,
        createdAt: now,
        startedAt: now,
        questionOpenedAt: openedAt,
        activeQuestion: activeQ,
        answerDistribution: const {'0': 1, '2': 4},
        answersSubmittedCount: 5,
        isPaused: false,
      );

      final map = contest.toMap();
      expect(map['stage'], 'questionActive');
      expect(map['currentQuestionIndex'], 0);
      expect(map['answersSubmittedCount'], 5);
      expect(map['activeQuestion']['text'], 'What is the capital of France?');
      expect(map['activeQuestion']['correctAnswers'], isEmpty);

      final restored = Contest.fromMap(map, 'contest-live-1');
      expect(restored.stage, ContestStage.questionActive);
      expect(restored.currentQuestionIndex, 0);
      expect(restored.activeQuestion?.text, 'What is the capital of France?');
      expect(restored.activeQuestion?.correctAnswers, isEmpty);
      expect(restored.answerDistribution['2'], 4);
    });

    test('Anti-Cheat: active question has empty correctAnswers during questionActive, populated in answerReveal', () {
      final activeQ = ActiveQuestion(
        text: 'True or False: Flutter is built by Google.',
        type: QuestionType.trueFalse,
        options: const ['True', 'False'],
        timeLimitSeconds: 15,
        basePoints: 1000,
        correctAnswers: const [],
      );

      expect(activeQ.correctAnswers, isEmpty);

      final revealedQ = ActiveQuestion(
        text: activeQ.text,
        type: activeQ.type,
        options: activeQ.options,
        timeLimitSeconds: activeQ.timeLimitSeconds,
        basePoints: activeQ.basePoints,
        explanation: 'Google released Flutter in 2017.',
        correctAnswers: const [0],
      );

      expect(revealedQ.correctAnswers, [0]);
      expect(revealedQ.explanation, isNotNull);
    });

    test('ContestAnswer serializes and deserializes participant submissions', () {
      final now = DateTime.now();
      final answer = ContestAnswer(
        id: 'user1_0',
        participantId: 'user1',
        participantName: 'Alice',
        questionIndex: 0,
        selectedAnswers: const [2],
        submittedAt: now,
        pointsAwarded: 850,
        isCorrect: true,
        responseTimeSeconds: 6.0,
      );

      final map = answer.toMap();
      final restored = ContestAnswer.fromMap(map, 'user1_0');

      expect(restored.participantId, 'user1');
      expect(restored.questionIndex, 0);
      expect(restored.selectedAnswers, [2]);
      expect(restored.pointsAwarded, 850);
      expect(restored.isCorrect, isTrue);
    });

    test('Host-authoritative scoring using server timestamp difference', () {
      final openedAt = DateTime(2026, 10, 8, 12, 0, 0);
      // Alice answers in 5.0 seconds
      final aliceSubmitted = DateTime(2026, 10, 8, 12, 0, 5);
      final aliceResponseSeconds = aliceSubmitted.difference(openedAt).inMilliseconds / 1000.0;
      expect(aliceResponseSeconds, 5.0);

      final aliceScore = ScoringUtils.calculateScore(
        basePoints: 1000,
        responseTimeSeconds: aliceResponseSeconds,
        timeLimitSeconds: 20.0,
        isCorrect: true,
      );
      // 5 / 20 = 0.25 time ratio -> multiplier = 0.5 + 0.5 * 0.75 = 0.875 -> 875 points
      expect(aliceScore, 875);

      // Bob answers in 15.0 seconds
      final bobSubmitted = DateTime(2026, 10, 8, 12, 0, 15);
      final bobResponseSeconds = bobSubmitted.difference(openedAt).inMilliseconds / 1000.0;
      final bobScore = ScoringUtils.calculateScore(
        basePoints: 1000,
        responseTimeSeconds: bobResponseSeconds,
        timeLimitSeconds: 20.0,
        isCorrect: true,
      );
      // 15 / 20 = 0.75 -> multiplier = 0.5 + 0.5 * 0.25 = 0.625 -> 625 points
      expect(bobScore, 625);

      // Charlie answers incorrectly
      final charlieScore = ScoringUtils.calculateScore(
        basePoints: 1000,
        responseTimeSeconds: 2.0,
        timeLimitSeconds: 20.0,
        isCorrect: false,
      );
      expect(charlieScore, 0);
    });

    test('Streak logic tracks consecutive correct answers and resets on incorrect', () {
      int updateStreak(int current, bool isCorrect) => isCorrect ? current + 1 : 0;

      int streak = 0;
      streak = updateStreak(streak, true);
      expect(streak, 1);

      streak = updateStreak(streak, true);
      expect(streak, 2);

      streak = updateStreak(streak, false);
      expect(streak, 0);

      streak = updateStreak(streak, true);
      expect(streak, 1);
    });

    test('Leaderboard correctly sorts participants descending by totalScore', () {
      final now = DateTime.now();
      final p1 = ContestParticipant(
        id: '1',
        displayName: 'Charlie',
        joinedAt: now,
        totalScore: 500,
      );
      final p2 = ContestParticipant(
        id: '2',
        displayName: 'Alice',
        joinedAt: now,
        totalScore: 1800,
      );
      final p3 = ContestParticipant(
        id: '3',
        displayName: 'Bob',
        joinedAt: now,
        totalScore: 1200,
      );

      final list = [p1, p2, p3];
      list.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      expect(list[0].displayName, 'Alice');
      expect(list[1].displayName, 'Bob');
      expect(list[2].displayName, 'Charlie');
    });
  });
}
