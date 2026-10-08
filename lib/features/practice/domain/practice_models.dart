import '../../quiz/domain/quiz_question.dart';

/// Represents a user's answer and outcome for a question in Solo Practice mode.
class PracticeAnswer {
  final int questionIndex;
  final QuizQuestion question;
  final List<dynamic> userAnswers;
  final bool isCorrect;
  final int pointsAwarded;
  final double responseTimeSeconds;
  final int streak;

  const PracticeAnswer({
    required this.questionIndex,
    required this.question,
    required this.userAnswers,
    required this.isCorrect,
    required this.pointsAwarded,
    required this.responseTimeSeconds,
    required this.streak,
  });

  /// User-friendly string representation of what the user answered
  String get formattedUserAnswer {
    if (userAnswers.isEmpty) return 'No answer (Time expired)';

    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        final idx = (userAnswers.first as num?)?.toInt();
        if (idx != null && idx >= 0 && idx < question.options.length) {
          return question.options[idx];
        }
        return 'Option #${idx ?? 0 + 1}';

      case QuestionType.multipleSelect:
        final indices = userAnswers.map((e) => (e as num).toInt()).toList();
        final names = indices
            .where((i) => i >= 0 && i < question.options.length)
            .map((i) => question.options[i]);
        return names.isEmpty ? 'None' : names.join(', ');

      case QuestionType.shortText:
      case QuestionType.numeric:
        return userAnswers.first.toString();

      case QuestionType.ordering:
        final indices = userAnswers.map((e) => (e as num).toInt()).toList();
        final names = indices
            .where((i) => i >= 0 && i < question.options.length)
            .map((i) => question.options[i]);
        return names.join('  ➔  ');
    }
  }

  /// User-friendly string representation of the expected correct answer
  String get formattedCorrectAnswer {
    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        if (question.correctAnswers.isNotEmpty) {
          final idx = question.correctAnswers.first;
          if (idx >= 0 && idx < question.options.length) {
            return question.options[idx];
          }
        }
        return 'Option #${question.correctAnswers.first + 1}';

      case QuestionType.multipleSelect:
        final names = question.correctAnswers
            .where((i) => i >= 0 && i < question.options.length)
            .map((i) => question.options[i]);
        return names.join(', ');

      case QuestionType.shortText:
      case QuestionType.numeric:
        return question.options.first;

      case QuestionType.ordering:
        final names = question.correctAnswers
            .where((i) => i >= 0 && i < question.options.length)
            .map((i) => question.options[i]);
        return names.join('  ➔  ');
    }
  }
}
