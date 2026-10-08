import 'package:flutter_test/flutter_test.dart';
import 'package:quizapp/core/constants/app_constants.dart';
import 'package:quizapp/features/quiz/domain/quiz.dart';
import 'package:quizapp/features/quiz/domain/quiz_question.dart';

void main() {
  group('QuizQuestion Domain Tests', () {
    test('Serializes to and from Map correctly', () {
      final question = QuizQuestion(
        id: 'q-101',
        text: 'What is the capital of France?',
        type: QuestionType.multipleChoice,
        options: const ['Berlin', 'Madrid', 'Paris', 'Rome'],
        correctAnswers: const [2],
        timeLimitSeconds: 30,
        basePoints: 1000,
        explanation: 'Paris is the capital and most populous city of France.',
        imageBase64: 'sample_base64_string',
      );

      final map = question.toMap();
      expect(map['id'], 'q-101');
      expect(map['text'], 'What is the capital of France?');
      expect(map['type'], 'multipleChoice');
      expect(map['options'], ['Berlin', 'Madrid', 'Paris', 'Rome']);
      expect(map['correctAnswers'], [2]);
      expect(map['timeLimitSeconds'], 30);
      expect(map['basePoints'], 1000);
      expect(map['explanation'], 'Paris is the capital and most populous city of France.');
      expect(map['imageBase64'], 'sample_base64_string');

      final reconstructed = QuizQuestion.fromMap(map);
      expect(reconstructed.id, question.id);
      expect(reconstructed.text, question.text);
      expect(reconstructed.type, question.type);
      expect(reconstructed.options, question.options);
      expect(reconstructed.correctAnswers, question.correctAnswers);
      expect(reconstructed.timeLimitSeconds, question.timeLimitSeconds);
      expect(reconstructed.basePoints, question.basePoints);
      expect(reconstructed.explanation, question.explanation);
      expect(reconstructed.imageBase64, question.imageBase64);
    });

    test('Validation enforces question text, minimum options, and valid correct answers', () {
      // Empty text
      final emptyText = QuizQuestion(
        id: '1',
        text: '',
        options: const ['A', 'B'],
        correctAnswers: const [0],
      );
      expect(emptyText.isValidForPublish, isFalse);
      expect(emptyText.validationError, contains('Question text cannot be empty'));

      // Less than 2 options
      final singleOption = QuizQuestion(
        id: '2',
        text: 'Valid Question',
        options: const ['Only One'],
        correctAnswers: const [0],
      );
      expect(singleOption.isValidForPublish, isFalse);
      expect(singleOption.validationError, contains('at least 2 options'));

      // Blank option
      final blankOption = QuizQuestion(
        id: '3',
        text: 'Valid Question',
        options: const ['Option 1', '   '],
        correctAnswers: const [0],
      );
      expect(blankOption.isValidForPublish, isFalse);
      expect(blankOption.validationError, contains('Option 2 cannot be empty'));

      // No correct answers selected
      final noCorrect = QuizQuestion(
        id: '4',
        text: 'Valid Question',
        options: const ['Option 1', 'Option 2'],
        correctAnswers: const [],
      );
      expect(noCorrect.isValidForPublish, isFalse);
      expect(noCorrect.validationError, contains('at least one correct answer'));

      // Out of bounds answer index
      final outOfBounds = QuizQuestion(
        id: '5',
        text: 'Valid Question',
        options: const ['Option 1', 'Option 2'],
        correctAnswers: const [5],
      );
      expect(outOfBounds.isValidForPublish, isFalse);
      expect(outOfBounds.validationError, contains('Invalid correct answer selection'));

      // Fully valid
      final valid = QuizQuestion(
        id: '6',
        text: 'Valid Question',
        options: const ['Option 1', 'Option 2', 'Option 3', 'Option 4'],
        correctAnswers: const [1],
      );
      expect(valid.isValidForPublish, isTrue);
      expect(valid.validationError, isNull);
    });

    test('Duplication generates new UUID and clones attributes', () {
      final original = QuizQuestion(
        id: 'orig-1',
        text: 'Original Question',
        options: const ['Red', 'Blue', 'Yellow', 'Green'],
        correctAnswers: const [0],
      );

      final duplicated = original.duplicate();
      expect(duplicated.id, isNot(equals(original.id)));
      expect(duplicated.text, 'Original Question (Copy)');
      expect(duplicated.options, original.options);
      expect(duplicated.correctAnswers, original.correctAnswers);
    });
  });

  group('Quiz Domain & Quota Tests', () {
    test('Serializes and deserializes Quiz model with nested questions and timestamps', () {
      final now = DateTime.now();
      final quiz = Quiz(
        id: 'quiz-123',
        creatorId: 'user-456',
        creatorName: 'Quiz Master',
        title: 'Science & Cosmos',
        description: 'Test your knowledge about astronomy',
        themeColor: 0xFF6C4AB6,
        isDraft: false,
        questions: [
          QuizQuestion(
            id: 'q-1',
            text: 'How many planets are in our solar system?',
            options: const ['7', '8', '9', '10'],
            correctAnswers: const [1],
            timeLimitSeconds: 20,
            basePoints: 1000,
          ),
          QuizQuestion(
            id: 'q-2',
            text: 'Is the sun a star?',
            options: const ['Yes', 'No'],
            correctAnswers: const [0],
            timeLimitSeconds: 10,
            basePoints: 500,
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      expect(quiz.questionsCount, 2);
      expect(quiz.totalTimeSeconds, 30);
      expect(quiz.totalPoints, 1500);

      final map = quiz.toMap();
      final reconstructed = Quiz.fromMap(map, 'quiz-123');

      expect(reconstructed.id, 'quiz-123');
      expect(reconstructed.creatorId, 'user-456');
      expect(reconstructed.creatorName, 'Quiz Master');
      expect(reconstructed.title, 'Science & Cosmos');
      expect(reconstructed.description, 'Test your knowledge about astronomy');
      expect(reconstructed.isDraft, isFalse);
      expect(reconstructed.questions.length, 2);
      expect(reconstructed.questions[0].text, 'How many planets are in our solar system?');
      expect(reconstructed.questions[1].text, 'Is the sun a star?');
    });

    test('Enforces 1 MB Firestore document quota correctly', () {
      // Normal size quiz
      final smallQuiz = Quiz.createDraft(
        creatorId: 'uid-1',
        creatorName: 'Author',
      ).copyWith(
        title: 'Lightweight Quiz',
        questions: [
          QuizQuestion(
            id: 'q-1',
            text: 'Question text',
            options: const ['A', 'B'],
            correctAnswers: const [0],
          ),
        ],
      );

      expect(smallQuiz.estimatedSizeBytes, lessThan(AppConstants.maxDocSizeBytes));
      expect(smallQuiz.isUnderDocLimit, isTrue);

      // Oversized quiz exceeding 1 MB limit (e.g. huge payload)
      final hugeString = 'X' * (1024 * 1024 + 100); // > 1 MB
      final hugeQuiz = smallQuiz.copyWith(
        questions: [
          QuizQuestion(
            id: 'q-huge',
            text: 'Heavy question',
            options: const ['A', 'B'],
            correctAnswers: const [0],
            imageBase64: hugeString,
          ),
        ],
      );

      expect(hugeQuiz.estimatedSizeBytes, greaterThan(AppConstants.maxDocSizeBytes));
      expect(hugeQuiz.isUnderDocLimit, isFalse);
      expect(hugeQuiz.publishValidationError, contains('exceeds the 1 MB Firestore limit'));
    });

    test('Publish validation prevents publishing draft without title or questions', () {
      final blankQuiz = Quiz.createDraft(
        creatorId: 'uid-1',
        creatorName: 'Author',
      );

      expect(blankQuiz.isValidForPublish, isFalse);
      expect(blankQuiz.publishValidationError, contains('Please enter a quiz title'));

      final titledQuizNoQuestions = blankQuiz.copyWith(title: 'Valid Title');
      expect(titledQuizNoQuestions.isValidForPublish, isFalse);
      expect(
        titledQuizNoQuestions.publishValidationError,
        contains('must contain at least 1 question'),
      );
    });

    test('Duplicating a quiz generates a fresh draft with cloned questions and updated title', () {
      final original = Quiz(
        id: 'orig-quiz',
        creatorId: 'user-1',
        creatorName: 'First Creator',
        title: 'Original Quiz',
        description: 'Original Description',
        isDraft: false,
        questions: [
          QuizQuestion(
            id: 'q-1',
            text: 'Question 1',
            options: const ['A', 'B'],
            correctAnswers: const [0],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final duplicated = original.duplicate(
        newCreatorId: 'user-2',
        newCreatorName: 'Second Creator',
      );

      expect(duplicated.id, isNot(equals(original.id)));
      expect(duplicated.creatorId, 'user-2');
      expect(duplicated.creatorName, 'Second Creator');
      expect(duplicated.title, 'Original Quiz (Copy)');
      expect(duplicated.isDraft, isTrue);
      expect(duplicated.questions.length, 1);
      expect(duplicated.questions[0].id, isNot(equals(original.questions[0].id)));
      expect(duplicated.questions[0].text, 'Question 1 (Copy)');
    });
  });
}
