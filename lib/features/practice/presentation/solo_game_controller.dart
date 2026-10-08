import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/scoring_utils.dart';
import '../../quiz/domain/quiz.dart';
import '../../quiz/domain/quiz_question.dart';
import '../domain/practice_models.dart';

class SoloGameState {
  final Quiz? quiz;
  final int currentQuestionIndex;
  final int remainingSeconds;
  final int totalQuestionSeconds;
  final int score;
  final int streak;
  final int highestStreak;
  final bool isAnswerRevealed;
  final bool isFinished;
  final List<dynamic> selectedAnswers;
  final String textAnswer;
  final List<int>? orderingList;
  final List<PracticeAnswer> history;
  final bool isLoading;
  final String? errorMessage;

  const SoloGameState({
    this.quiz,
    this.currentQuestionIndex = 0,
    this.remainingSeconds = 20,
    this.totalQuestionSeconds = 20,
    this.score = 0,
    this.streak = 0,
    this.highestStreak = 0,
    this.isAnswerRevealed = false,
    this.isFinished = false,
    this.selectedAnswers = const [],
    this.textAnswer = '',
    this.orderingList,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  QuizQuestion? get currentQuestion {
    if (quiz == null ||
        currentQuestionIndex < 0 ||
        currentQuestionIndex >= quiz!.questions.length) {
      return null;
    }
    return quiz!.questions[currentQuestionIndex];
  }

  int get totalQuestions => quiz?.questions.length ?? 0;

  bool get isLastQuestion =>
      totalQuestions > 0 && currentQuestionIndex >= totalQuestions - 1;

  double get progressRatio =>
      totalQuestions > 0 ? (currentQuestionIndex + 1) / totalQuestions : 0.0;

  int get totalCorrect => history.where((a) => a.isCorrect).length;

  int get accuracyPercent =>
      history.isEmpty ? 0 : ((totalCorrect / history.length) * 100).round();

  double get averageResponseTime => history.isEmpty
      ? 0.0
      : history.fold(0.0, (sum, a) => sum + a.responseTimeSeconds) /
          history.length;

  PracticeAnswer? get lastAnswer => history.isNotEmpty ? history.last : null;

  SoloGameState copyWith({
    Quiz? quiz,
    int? currentQuestionIndex,
    int? remainingSeconds,
    int? totalQuestionSeconds,
    int? score,
    int? streak,
    int? highestStreak,
    bool? isAnswerRevealed,
    bool? isFinished,
    List<dynamic>? selectedAnswers,
    String? textAnswer,
    List<int>? orderingList,
    bool clearOrdering = false,
    List<PracticeAnswer>? history,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SoloGameState(
      quiz: quiz ?? this.quiz,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      totalQuestionSeconds:
          totalQuestionSeconds ?? this.totalQuestionSeconds,
      score: score ?? this.score,
      streak: streak ?? this.streak,
      highestStreak: highestStreak ?? this.highestStreak,
      isAnswerRevealed: isAnswerRevealed ?? this.isAnswerRevealed,
      isFinished: isFinished ?? this.isFinished,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      textAnswer: textAnswer ?? this.textAnswer,
      orderingList:
          clearOrdering ? null : (orderingList ?? this.orderingList),
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class SoloGameController extends Notifier<SoloGameState> {
  Timer? _countdownTimer;

  @override
  SoloGameState build() {
    ref.onDispose(() {
      _countdownTimer?.cancel();
    });
    return const SoloGameState();
  }


  /// Initialize and start a practice session with the given quiz
  void initGame(Quiz quiz) {
    _countdownTimer?.cancel();

    if (quiz.questions.isEmpty) {
      state = state.copyWith(
        quiz: quiz,
        isFinished: true,
        errorMessage: 'This quiz has no questions to practice.',
      );
      return;
    }

    final firstQ = quiz.questions[0];
    List<int>? initialOrder;
    if (firstQ.type == QuestionType.ordering) {
      final list = List.generate(firstQ.options.length, (i) => i);
      initialOrder = list.length > 1 ? list.reversed.toList() : list;
    }

    state = SoloGameState(
      quiz: quiz,
      currentQuestionIndex: 0,
      remainingSeconds: firstQ.timeLimitSeconds,
      totalQuestionSeconds: firstQ.timeLimitSeconds,
      score: 0,
      streak: 0,
      highestStreak: 0,
      isAnswerRevealed: false,
      isFinished: false,
      selectedAnswers: initialOrder ?? [],
      textAnswer: '',
      orderingList: initialOrder,
      history: const [],
    );

    _startTimer();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.remainingSeconds > 1) {
        state = state.copyWith(remainingSeconds: state.remainingSeconds - 1);
      } else {
        timer.cancel();
        state = state.copyWith(remainingSeconds: 0);
        submitAnswer(); // Auto-submit when time runs out
      }
    });
  }

  /// Selects or deselects an option (for Multiple Choice / Multiple Select)
  void toggleOption(int index, {required bool isMultiSelect}) {
    if (state.isAnswerRevealed || state.isFinished) return;

    if (!isMultiSelect) {
      state = state.copyWith(selectedAnswers: [index]);
    } else {
      final currentList = List<dynamic>.from(state.selectedAnswers);
      if (currentList.contains(index)) {
        currentList.remove(index);
      } else {
        currentList.add(index);
      }
      state = state.copyWith(selectedAnswers: currentList);
    }
  }

  /// Sets text answer for short text or numeric questions
  void setTextAnswer(String text) {
    if (state.isAnswerRevealed || state.isFinished) return;
    state = state.copyWith(
      textAnswer: text,
      selectedAnswers: text.trim().isEmpty ? [] : [text.trim()],
    );
  }

  /// Updates reordered list for ordering questions
  void setOrdering(List<int> order) {
    if (state.isAnswerRevealed || state.isFinished) return;
    state = state.copyWith(
      orderingList: order,
      selectedAnswers: order,
    );
  }

  /// Evaluates correctness and scores the submission
  void submitAnswer() {
    if (state.isAnswerRevealed || state.isFinished) return;
    _countdownTimer?.cancel();

    final q = state.currentQuestion;
    if (q == null) return;

    // Determine final submission values
    List<dynamic> submission;
    if (q.type == QuestionType.ordering) {
      submission = state.orderingList ?? List.generate(q.options.length, (i) => i);
    } else if (q.type == QuestionType.shortText || q.type == QuestionType.numeric) {
      submission = state.textAnswer.trim().isEmpty ? [] : [state.textAnswer.trim()];
    } else {
      submission = state.selectedAnswers;
    }

    final isCorrect = checkCorrectness(
      question: q,
      selectedAnswers: submission,
    );

    final responseTime = (state.totalQuestionSeconds - state.remainingSeconds)
        .toDouble()
        .clamp(0.0, state.totalQuestionSeconds.toDouble());

    int pointsAwarded = 0;
    int nextStreak = 0;

    if (isCorrect) {
      nextStreak = state.streak + 1;
      final speedPoints = ScoringUtils.calculateScore(
        basePoints: q.basePoints,
        responseTimeSeconds: responseTime,
        timeLimitSeconds: state.totalQuestionSeconds.toDouble(),
        isCorrect: true,
      );

      // Streak bonus: +100 for streak 2, +200 for streak 3, etc.
      final streakBonus = nextStreak > 1 ? (nextStreak - 1) * 100 : 0;
      pointsAwarded = speedPoints + streakBonus;
    } else {
      nextStreak = 0;
      pointsAwarded = 0;
    }

    final answerResult = PracticeAnswer(
      questionIndex: state.currentQuestionIndex,
      question: q,
      userAnswers: submission,
      isCorrect: isCorrect,
      pointsAwarded: pointsAwarded,
      responseTimeSeconds: responseTime,
      streak: nextStreak,
    );

    final updatedHistory = List<PracticeAnswer>.from(state.history)..add(answerResult);

    state = state.copyWith(
      isAnswerRevealed: true,
      score: state.score + pointsAwarded,
      streak: nextStreak,
      highestStreak: max(state.highestStreak, nextStreak),
      history: updatedHistory,
      selectedAnswers: submission,
    );
  }

  /// Advances to the next question or finishes the quiz
  void nextQuestion() {
    _countdownTimer?.cancel();

    if (state.isLastQuestion) {
      state = state.copyWith(isFinished: true);
      return;
    }

    final nextIndex = state.currentQuestionIndex + 1;
    final nextQ = state.quiz!.questions[nextIndex];

    List<int>? initialOrder;
    if (nextQ.type == QuestionType.ordering) {
      final list = List.generate(nextQ.options.length, (i) => i);
      initialOrder = list.length > 1 ? list.reversed.toList() : list;
    }

    state = state.copyWith(
      currentQuestionIndex: nextIndex,
      remainingSeconds: nextQ.timeLimitSeconds,
      totalQuestionSeconds: nextQ.timeLimitSeconds,
      isAnswerRevealed: false,
      selectedAnswers: initialOrder ?? [],
      textAnswer: '',
      orderingList: initialOrder,
      clearOrdering: initialOrder == null,
    );

    _startTimer();
  }

  /// Restart the active quiz from question 1
  void restartGame() {
    if (state.quiz != null) {
      initGame(state.quiz!);
    }
  }

  /// Validates user answers against expected answers across all 6 question types
  static bool checkCorrectness({
    required QuizQuestion question,
    required List<dynamic> selectedAnswers,
  }) {
    if (selectedAnswers.isEmpty) return false;

    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        final selectedIndex = (selectedAnswers.first as num?)?.toInt();
        return selectedIndex != null &&
            question.correctAnswers.contains(selectedIndex);

      case QuestionType.multipleSelect:
        final selectedSet =
            selectedAnswers.map((e) => (e as num).toInt()).toSet();
        final correctSet = question.correctAnswers.toSet();
        return selectedSet.length == correctSet.length &&
            selectedSet.containsAll(correctSet);

      case QuestionType.shortText:
        final userText = selectedAnswers.first.toString().trim().toLowerCase();
        return question.options.any(
          (opt) => opt.trim().toLowerCase() == userText,
        );

      case QuestionType.numeric:
        final userRaw = selectedAnswers.first.toString().trim();
        final userNum = double.tryParse(userRaw);
        if (userNum == null) return false;
        return question.options.any((opt) {
          final targetNum = double.tryParse(opt.trim());
          if (targetNum == null) return false;
          return (userNum - targetNum).abs() < 0.0001;
        });

      case QuestionType.ordering:
        final selectedList =
            selectedAnswers.map((e) => (e as num).toInt()).toList();
        if (selectedList.length != question.correctAnswers.length) return false;
        for (int i = 0; i < selectedList.length; i++) {
          if (selectedList[i] != question.correctAnswers[i]) return false;
        }
        return true;
    }
  }
}

/// Solo game state provider
final soloGameControllerProvider =
    NotifierProvider<SoloGameController, SoloGameState>(
  SoloGameController.new,
);

