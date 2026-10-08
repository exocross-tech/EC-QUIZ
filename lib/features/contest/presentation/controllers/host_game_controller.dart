import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizapp/core/utils/scoring_utils.dart';
import 'package:quizapp/features/quiz/data/firestore_quiz_repository.dart';
import 'package:quizapp/features/quiz/domain/quiz.dart';
import 'package:quizapp/features/quiz/domain/quiz_question.dart';
import 'package:quizapp/features/contest/data/firestore_contest_repository.dart';
import 'package:quizapp/features/contest/domain/contest.dart';
import 'package:quizapp/features/contest/domain/contest_participant.dart';

class HostGameState {
  final bool isLoading;
  final String? errorMessage;
  final Quiz? loadedQuiz;

  const HostGameState({
    this.isLoading = false,
    this.errorMessage,
    this.loadedQuiz,
  });

  HostGameState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Quiz? loadedQuiz,
  }) {
    return HostGameState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      loadedQuiz: loadedQuiz ?? this.loadedQuiz,
    );
  }
}

class HostGameController extends Notifier<HostGameState> {
  @override
  HostGameState build() {
    return const HostGameState();
  }

  /// Preloads the full host quiz containing the secret correct answers
  Future<Quiz?> loadQuizForContest(String quizId) async {
    if (state.loadedQuiz?.id == quizId) return state.loadedQuiz;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final quizRepo = ref.read(quizRepositoryProvider);
      final quiz = await quizRepo.getQuiz(quizId);
      if (quiz == null) {
        throw Exception('Quiz not found. It may have been deleted.');
      }
      state = state.copyWith(isLoading: false, loadedQuiz: quiz);
      return quiz;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  /// Starts the game from the lobby into question 0
  Future<bool> startLiveGame({
    required String contestId,
    required String quizId,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final quiz = await loadQuizForContest(quizId);
      if (quiz == null || quiz.questions.isEmpty) {
        throw Exception('This quiz has no questions.');
      }

      final contestRepo = ref.read(contestRepositoryProvider);
      await contestRepo.startLiveGame(
        contestId: contestId,
        firstQuestion: quiz.questions[0],
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Host reveals answers, validates correctness, and executes single-batch scoring
  Future<bool> revealAnswers({
    required Contest contest,
    required List<ContestParticipant> participants,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final quiz = await loadQuizForContest(contest.quizId);
      if (quiz == null) throw Exception('Quiz not loaded.');

      final qIndex = contest.currentQuestionIndex;
      if (qIndex < 0 || qIndex >= quiz.questions.length) {
        throw Exception('Invalid question index.');
      }

      final question = quiz.questions[qIndex];
      final contestRepo = ref.read(contestRepositoryProvider);

      // Fetch all answers submitted for this question
      final answers = await contestRepo.getQuestionAnswers(
        contestId: contest.id,
        questionIndex: qIndex,
      );

      final openTime = contest.questionOpenedAt ?? contest.createdAt;
      final participantPoints = <String, int>{};
      final participantCorrectness = <String, bool>{};
      final participantStreaks = <String, int>{};

      // Distribution map initialization
      final distribution = <String, int>{};
      for (int i = 0; i < question.options.length; i++) {
        distribution[i.toString()] = 0;
      }

      // Map participants for streak lookup
      final participantMap = {for (final p in participants) p.id: p};

      for (final ans in answers) {
        // Aggregate distribution
        for (final sel in ans.selectedAnswers) {
          final key = sel.toString();
          distribution[key] = (distribution[key] ?? 0) + 1;
        }

        // Host server-timestamp response time calculation
        final responseSeconds =
            (ans.submittedAt.difference(openTime).inMilliseconds) / 1000.0;

        // Check correctness based on question type
        final isCorrect = _checkCorrectness(
          question: question,
          selectedAnswers: ans.selectedAnswers,
        );

        final points = ScoringUtils.calculateScore(
          basePoints: question.basePoints,
          responseTimeSeconds: responseSeconds,
          timeLimitSeconds: question.timeLimitSeconds.toDouble(),
          isCorrect: isCorrect,
        );

        participantPoints[ans.participantId] = points;
        participantCorrectness[ans.participantId] = isCorrect;

        final currentStreak = participantMap[ans.participantId]?.streak ?? 0;
        participantStreaks[ans.participantId] = isCorrect ? currentStreak + 1 : 0;
      }

      // Any participants who didn't submit an answer get 0 points and streak reset
      for (final p in participants) {
        if (!participantPoints.containsKey(p.id)) {
          participantPoints[p.id] = 0;
          participantCorrectness[p.id] = false;
          participantStreaks[p.id] = 0;
        }
      }

      // Execute atomic batch reveal and scoreboard update
      await contestRepo.revealAnswers(
        contestId: contest.id,
        questionIndex: qIndex,
        correctAnswers: question.correctAnswers,
        options: question.options,
        explanation: question.explanation,
        distribution: distribution,
        participantPoints: participantPoints,
        participantCorrectness: participantCorrectness,
        participantStreaks: participantStreaks,
      );

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Host triggers leaderboard view
  Future<bool> showLeaderboard(String contestId) async {
    try {
      await ref.read(contestRepositoryProvider).showLeaderboard(contestId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Host advances to next question or concludes with podium
  Future<bool> nextQuestion(Contest contest) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final quiz = await loadQuizForContest(contest.quizId);
      if (quiz == null) throw Exception('Quiz not loaded.');

      final nextIndex = contest.currentQuestionIndex + 1;
      final contestRepo = ref.read(contestRepositoryProvider);

      if (nextIndex < quiz.questions.length) {
        // Move to next question
        await contestRepo.nextQuestion(
          contestId: contest.id,
          nextIndex: nextIndex,
          nextQuestion: quiz.questions[nextIndex],
        );
      } else {
        // Final question completed -> Show Podium!
        await contestRepo.showPodium(contest.id);
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Host toggles countdown pause
  Future<bool> togglePause(Contest contest) async {
    try {
      await ref.read(contestRepositoryProvider).setContestPaused(
            contestId: contest.id,
            isPaused: !contest.isPaused,
          );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Host ends contest
  Future<bool> endContest(String contestId) async {
    try {
      await ref.read(contestRepositoryProvider).endContest(contestId);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  static bool _checkCorrectness({
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

final hostGameControllerProvider =
    NotifierProvider<HostGameController, HostGameState>(
  HostGameController.new,
);
