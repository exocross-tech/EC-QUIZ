import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizapp/features/practice/data/sample_quizzes.dart';
import 'package:quizapp/features/practice/domain/practice_models.dart';
import 'package:quizapp/features/practice/presentation/solo_game_controller.dart';
import 'package:quizapp/features/quiz/domain/quiz.dart';
import 'package:quizapp/features/quiz/domain/quiz_question.dart';


void main() {
  group('Phase 6 Solo Practice - Starter Quizzes Domain Tests', () {
    test('All sample quizzes are valid and ready for play', () {
      final samples = SampleQuizzes.all;
      expect(samples.length, equals(3));

      for (final quiz in samples) {
        expect(quiz.id, isNotEmpty);
        expect(quiz.title, isNotEmpty);
        expect(quiz.questions, isNotEmpty);
        expect(quiz.publishValidationError, isNull);
        expect(quiz.isValidForPublish, isTrue);
      }
    });

    test('Sample quizzes encompass all 6 question types', () {
      final samples = SampleQuizzes.all;
      final allTypes = samples
          .expand((q) => q.questions)
          .map((q) => q.type)
          .toSet();

      for (final type in QuestionType.values) {
        expect(allTypes.contains(type), isTrue,
            reason: 'Sample quizzes must include question type ${type.name}');
      }
    });

    test('SampleQuizzes.getById finds existing sample and returns null for unknown', () {
      final trivia = SampleQuizzes.getById('sample_general_trivia');
      expect(trivia, isNotNull);
      expect(trivia?.title, equals('General Trivia & Wonders'));

      final nonExistent = SampleQuizzes.getById('unknown_id_999');
      expect(nonExistent, isNull);
    });
  });

  group('Phase 6 Solo Practice - Answer Correctness Evaluator Tests', () {
    test('Multiple Choice correctness', () {
      final q = QuizQuestion(
        id: 'q1',
        text: 'Capital of France?',
        type: QuestionType.multipleChoice,
        options: ['Berlin', 'Madrid', 'Paris', 'Rome'],
        correctAnswers: [2],
      );

      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [2]), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [0]), isFalse);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: []), isFalse);
    });

    test('True / False correctness', () {
      final q = QuizQuestion(
        id: 'q2',
        text: 'The sky is blue.',
        type: QuestionType.trueFalse,
        options: ['True', 'False'],
        correctAnswers: [0],
      );

      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [0]), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [1]), isFalse);
    });

    test('Multiple Select correctness', () {
      final q = QuizQuestion(
        id: 'q3',
        text: 'Select even numbers:',
        type: QuestionType.multipleSelect,
        options: ['1', '2', '3', '4'],
        correctAnswers: [1, 3],
      );

      // Exact set match required
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [1, 3]), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [3, 1]), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [1]), isFalse);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [1, 2, 3]), isFalse);
    });

    test('Short Text correctness is case-insensitive', () {
      final q = QuizQuestion(
        id: 'q4',
        text: 'Chemical symbol for gold?',
        type: QuestionType.shortText,
        options: ['Au', 'AU', 'au'],
        correctAnswers: [0],
      );

      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['Au']), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['au']), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['AU']), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['Ag']), isFalse);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['']), isFalse);
    });

    test('Numeric correctness parses numbers with tolerance', () {
      final q = QuizQuestion(
        id: 'q5',
        text: 'Freezing point of water in Celsius?',
        type: QuestionType.numeric,
        options: ['0'],
        correctAnswers: [0],
      );

      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['0']), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['0.0']), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['32']), isFalse);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: ['abc']), isFalse);
    });

    test('Ordering correctness checks exact sequence', () {
      final q = QuizQuestion(
        id: 'q6',
        text: 'Order numbers ascending:',
        type: QuestionType.ordering,
        options: ['One', 'Two', 'Three'],
        correctAnswers: [0, 1, 2],
      );

      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [0, 1, 2]), isTrue);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [2, 1, 0]), isFalse);
      expect(SoloGameController.checkCorrectness(question: q, selectedAnswers: [0, 2, 1]), isFalse);
    });
  });

  group('Phase 6 Solo Practice - Controller Game Lifecycle & Scoring Tests', () {
    late Quiz testQuiz;

    setUp(() {
      final now = DateTime.now();
      testQuiz = Quiz(
        id: 'test_practice_quiz',
        creatorId: 'user1',
        creatorName: 'Tester',
        title: 'Solo Practice Test',
        description: 'Test quiz for solo controller',
        themeColor: 0xFF6C4AB6,
        isDraft: false,
        createdAt: now,
        updatedAt: now,
        questions: [
          QuizQuestion(
            id: 'q1',
            text: 'Question 1',
            type: QuestionType.multipleChoice,
            options: ['A', 'B', 'C', 'D'],
            correctAnswers: [0],
            timeLimitSeconds: 20,
            basePoints: 1000,
            explanation: 'A is correct.',
          ),
          QuizQuestion(
            id: 'q2',
            text: 'Question 2',
            type: QuestionType.trueFalse,
            options: ['True', 'False'],
            correctAnswers: [0],
            timeLimitSeconds: 20,
            basePoints: 1000,
            explanation: 'True is correct.',
          ),
        ],
      );
    });

    test('initGame initializes state and question 0', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(soloGameControllerProvider.notifier);
      controller.initGame(testQuiz);

      final state = container.read(soloGameControllerProvider);
      expect(state.quiz?.id, equals(testQuiz.id));
      expect(state.currentQuestionIndex, equals(0));
      expect(state.score, equals(0));
      expect(state.streak, equals(0));
      expect(state.isAnswerRevealed, isFalse);
      expect(state.isFinished, isFalse);
      expect(state.totalQuestions, equals(2));
    });

    test('submitAnswer awards points on correct answer and builds streak', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(soloGameControllerProvider.notifier);
      controller.initGame(testQuiz);

      // Select correct option A (index 0)
      controller.toggleOption(0, isMultiSelect: false);
      controller.submitAnswer();

      final state = container.read(soloGameControllerProvider);
      expect(state.isAnswerRevealed, isTrue);
      expect(state.streak, equals(1));
      expect(state.highestStreak, equals(1));
      expect(state.score, greaterThan(0));
      expect(state.history.length, equals(1));
      expect(state.history.first.isCorrect, isTrue);
    });

    test('Consecutive correct answers award streak bonuses', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(soloGameControllerProvider.notifier);
      controller.initGame(testQuiz);

      // Q1: Answer correctly
      controller.toggleOption(0, isMultiSelect: false);
      controller.submitAnswer();
      final scoreAfterQ1 = container.read(soloGameControllerProvider).score;
      expect(container.read(soloGameControllerProvider).streak, equals(1));

      // Advance to Q2
      controller.nextQuestion();
      expect(container.read(soloGameControllerProvider).currentQuestionIndex, equals(1));
      expect(container.read(soloGameControllerProvider).isAnswerRevealed, isFalse);

      // Q2: Answer correctly (True = index 0)
      controller.toggleOption(0, isMultiSelect: false);
      controller.submitAnswer();

      final state = container.read(soloGameControllerProvider);
      expect(state.streak, equals(2));
      expect(state.highestStreak, equals(2));
      // Second correct answer includes streak bonus
      final q2Points = state.history[1].pointsAwarded;
      expect(q2Points, greaterThan(state.history[0].pointsAwarded - 100));
      expect(state.score, equals(scoreAfterQ1 + q2Points));

      // Final question complete -> finish
      controller.nextQuestion();
      final finalState = container.read(soloGameControllerProvider);
      expect(finalState.isFinished, isTrue);
      expect(finalState.accuracyPercent, equals(100));
    });

    test('Incorrect answer awards 0 points and resets streak', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(soloGameControllerProvider.notifier);
      controller.initGame(testQuiz);

      // Q1: Answer incorrectly (option B = index 1)
      controller.toggleOption(1, isMultiSelect: false);
      controller.submitAnswer();

      final state = container.read(soloGameControllerProvider);
      expect(state.isAnswerRevealed, isTrue);
      expect(state.streak, equals(0));
      expect(state.score, equals(0));
      expect(state.history.first.isCorrect, isFalse);
      expect(state.history.first.pointsAwarded, equals(0));
    });
  });


  group('Phase 6 Solo Practice - PracticeAnswer Formatting Tests', () {
    test('Formats user and correct answers clearly for review screen', () {
      final q = QuizQuestion(
        id: 'ord1',
        text: 'Chronological order',
        type: QuestionType.ordering,
        options: ['Alpha', 'Beta', 'Gamma'],
        correctAnswers: [0, 1, 2],
      );

      final ans = PracticeAnswer(
        questionIndex: 0,
        question: q,
        userAnswers: [2, 1, 0],
        isCorrect: false,
        pointsAwarded: 0,
        responseTimeSeconds: 5.0,
        streak: 0,
      );

      expect(ans.formattedUserAnswer, equals('Gamma  ➔  Beta  ➔  Alpha'));
      expect(ans.formattedCorrectAnswer, equals('Alpha  ➔  Beta  ➔  Gamma'));
    });
  });
}
