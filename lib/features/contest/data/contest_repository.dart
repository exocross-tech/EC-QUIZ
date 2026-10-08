import '../../quiz/domain/quiz.dart';
import '../domain/contest.dart';
import '../domain/contest_participant.dart';

abstract class ContestRepository {
  /// Watches the real-time state of a specific contest
  Stream<Contest?> watchContest(String contestId);

  /// Watches the real-time list of participants in a contest
  Stream<List<ContestParticipant>> watchParticipants(String contestId);

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
  });

  /// Marks a contest as ended and deactivates its join code
  Future<void> endContest(String contestId);
}
