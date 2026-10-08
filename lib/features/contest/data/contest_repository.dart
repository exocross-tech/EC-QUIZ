import '../../quiz/domain/quiz.dart';
import '../../quiz/domain/quiz_question.dart';
import '../domain/contest.dart';
import '../domain/contest_answer.dart';
import '../domain/contest_participant.dart';

abstract class ContestRepository {
  /// Watches the real-time state of a specific contest
  Stream<Contest?> watchContest(String contestId);

  /// Watches the real-time list of participants in a contest
  Stream<List<ContestParticipant>> watchParticipants(String contestId);

  /// Fetches the participants of a contest
  Future<List<ContestParticipant>> getParticipants(String contestId);

  /// Creates and launches a new contest from a Quiz with a unique 6-character code
  Future<Contest> createContest({
    required Quiz quiz,
    required String hostId,
    required String hostName,
    String? pin,
    int maxParticipants = 20,
  });

  /// Looks up an active lobby contest by its 6-character join code
  Future<Contest?> findContestByJoinCode(String joinCode);

  /// Registers a player into a contest lobby (validates PIN, max capacity, and kick status)
  Future<void> joinContest({
    required String contestId,
    required ContestParticipant participant,
    String? pinEntered,
  });

  /// Host kicks a participant from the contest
  Future<void> kickParticipant({
    required String contestId,
    required String participantId,
  });

  /// Participant leaves the lobby voluntarily
  Future<void> leaveContest({
    required String contestId,
    required String participantId,
  });

  /// Updates contest status (e.g. to inProgress or ended)
  Future<void> updateContestStatus({
    required String contestId,
    required ContestStatus status,
    String? endedReason,
  });

  /// Marks a contest as ended and deactivates its join code
  Future<void> endContest(String contestId, {String? endedReason});

  // --- LIVE GAMEPLAY (PHASE 4) ---

  /// Host transitions contest from lobby into active live game on question 0
  Future<void> startLiveGame({
    required String contestId,
    required QuizQuestion firstQuestion,
  });

  /// Participant submits their selected answer with a server timestamp
  Future<void> submitAnswer({
    required String contestId,
    required String participantId,
    required String participantName,
    required int questionIndex,
    required List<dynamic> selectedAnswers,
  });

  /// Real-time stream of the participant's answer for the active question
  Stream<ContestAnswer?> watchParticipantAnswer({
    required String contestId,
    required String participantId,
    required int questionIndex,
  });

  /// Fetches all participant answers submitted for a specific question
  Future<List<ContestAnswer>> getQuestionAnswers({
    required String contestId,
    required int questionIndex,
  });

  /// Host reveals answers, publishes correct answers, explanation, option distribution, and updates scores in a single batch
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
  });

  /// Host shows the leaderboard
  Future<void> showLeaderboard(String contestId);

  /// Host advances to the next question
  Future<void> nextQuestion({
    required String contestId,
    required int nextIndex,
    required QuizQuestion nextQuestion,
  });

  /// Host ends questions and transitions to the final podium
  Future<void> showPodium(String contestId);

  /// Host pauses or resumes the question countdown
  Future<void> setContestPaused({
    required String contestId,
    required bool isPaused,
  });
}
