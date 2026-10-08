import 'package:flutter_test/flutter_test.dart';
import 'package:quizapp/features/quiz/domain/quiz_question.dart';

void main() {
  group('Phase 5 - Question Types Domain & Validation Tests', () {
    test('emptyForType creates valid defaults for all 6 types', () {
      for (final type in QuestionType.values) {
        final q = QuizQuestion.emptyForType(type);
        expect(q.type, equals(type));
        expect(q.text, isEmpty);
      }
    });

    test('Multiple Choice validation', () {
      final valid = QuizQuestion(
        id: '1',
        text: 'What is the capital of France?',
        type: QuestionType.multipleChoice,
        options: const ['Paris', 'London', 'Berlin'],
        correctAnswers: const [0],
      );
      expect(valid.isValidForPublish, isTrue);

      final invalidTooFew = valid.copyWith(options: const ['Paris']);
      expect(invalidTooFew.isValidForPublish, isFalse);

      final invalidMultipleCorrect = valid.copyWith(correctAnswers: const [0, 1]);
      expect(invalidMultipleCorrect.isValidForPublish, isFalse);
    });

    test('True / False validation', () {
      final valid = QuizQuestion(
        id: '2',
        text: 'The Earth is round.',
        type: QuestionType.trueFalse,
        options: const ['True', 'False'],
        correctAnswers: const [0],
      );
      expect(valid.isValidForPublish, isTrue);

      final invalidOptionsCount = valid.copyWith(options: const ['True', 'False', 'Maybe']);
      expect(invalidOptionsCount.isValidForPublish, isFalse);
    });

    test('Multiple Select validation', () {
      final valid = QuizQuestion(
        id: '3',
        text: 'Select prime numbers:',
        type: QuestionType.multipleSelect,
        options: const ['2', '3', '4', '5'],
        correctAnswers: const [0, 1, 3],
      );
      expect(valid.isValidForPublish, isTrue);

      final invalidNoAnswers = valid.copyWith(correctAnswers: const []);
      expect(invalidNoAnswers.isValidForPublish, isFalse);
    });

    test('Short Text validation', () {
      final valid = QuizQuestion(
        id: '4',
        text: 'Name the largest ocean on Earth:',
        type: QuestionType.shortText,
        options: const ['Pacific', 'Pacific Ocean'],
        correctAnswers: const [0],
      );
      expect(valid.isValidForPublish, isTrue);

      final invalidEmpty = valid.copyWith(options: const ['']);
      expect(invalidEmpty.isValidForPublish, isFalse);
    });

    test('Numeric validation', () {
      final valid = QuizQuestion(
        id: '5',
        text: 'What year did Apollo 11 land on the moon?',
        type: QuestionType.numeric,
        options: const ['1969'],
        correctAnswers: const [0],
      );
      expect(valid.isValidForPublish, isTrue);

      final invalidNotNumber = valid.copyWith(options: const ['nineteen-sixty-nine']);
      expect(invalidNotNumber.isValidForPublish, isFalse);
    });

    test('Ordering validation', () {
      final valid = QuizQuestion(
        id: '6',
        text: 'Arrange historical events chronologically:',
        type: QuestionType.ordering,
        options: const ['WWI', 'WWII', 'Moon Landing', 'Fall of Berlin Wall'],
        correctAnswers: const [0, 1, 2, 3],
      );
      expect(valid.isValidForPublish, isTrue);

      final invalidTooFew = valid.copyWith(options: const ['WWI', 'WWII']);
      expect(invalidTooFew.isValidForPublish, isFalse);
    });

    test('All question types serialize toMap and fromMap correctly', () {
      for (final type in QuestionType.values) {
        final original = QuizQuestion.emptyForType(type).copyWith(
          text: 'Test question for ${type.name}',
        );
        final map = original.toMap();
        final deserialized = QuizQuestion.fromMap(map);

        expect(deserialized.id, equals(original.id));
        expect(deserialized.type, equals(original.type));
        expect(deserialized.text, equals(original.text));
        expect(deserialized.options, equals(original.options));
        expect(deserialized.correctAnswers, equals(original.correctAnswers));
      }
    });
  });
}
