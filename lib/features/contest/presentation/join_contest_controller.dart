import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/firestore_contest_repository.dart';
import '../domain/contest.dart';
import '../domain/contest_participant.dart';

class JoinContestState {
  final bool isLoading;
  final String? errorMessage;
  final Contest? contestFound;
  final bool needsPin;
  final bool isJoined;

  const JoinContestState({
    this.isLoading = false,
    this.errorMessage,
    this.contestFound,
    this.needsPin = false,
    this.isJoined = false,
  });

  JoinContestState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    Contest? contestFound,
    bool? needsPin,
    bool? isJoined,
  }) {
    return JoinContestState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      contestFound: contestFound ?? this.contestFound,
      needsPin: needsPin ?? this.needsPin,
      isJoined: isJoined ?? this.isJoined,
    );
  }
}

class JoinContestController extends Notifier<JoinContestState> {
  @override
  JoinContestState build() {
    return const JoinContestState();
  }

  void reset() {
    state = const JoinContestState();
  }

  Future<Contest?> submitCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.length != 6) {
      state = state.copyWith(errorMessage: 'Please enter a valid 6-character code.');
      return null;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repo = ref.read(contestRepositoryProvider);
      final contest = await repo.findContestByJoinCode(cleanCode);

      if (contest == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No active contest found with code "$cleanCode". Check with your host!',
        );
        return null;
      }

      if (contest.hasPin) {
        // Needs PIN before joining
        state = state.copyWith(
          isLoading: false,
          contestFound: contest,
          needsPin: true,
        );
        return contest;
      }

      // No PIN needed, join directly
      final joined = await _join(contest: contest, pin: null);
      if (joined) {
        return contest;
      }
      return null;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> submitPinAndJoin(String pin) async {
    final contest = state.contestFound;
    if (contest == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    return _join(contest: contest, pin: pin.trim());
  }

  Future<bool> _join({required Contest contest, String? pin}) async {
    try {
      final user = ref.read(authStateProvider).asData?.value;
      final profile = ref.read(currentUserProfileProvider).asData?.value;

      if (user == null) {
        throw Exception('Please sign in before joining a contest.');
      }

      final participant = ContestParticipant(
        id: user.id,
        displayName: profile?.displayName ?? user.displayName ?? 'Player',
        avatarType: profile?.avatarType ?? 'preset',
        avatarPresetId: profile?.avatarPresetId ?? 'lion',
        avatarColor: profile?.avatarColor ?? '#E21B3C',
        avatarBase64: profile?.avatarBase64,
        joinedAt: DateTime.now(),
        totalScore: 0,
      );

      final repo = ref.read(contestRepositoryProvider);
      await repo.joinContest(
        contestId: contest.id,
        participant: participant,
        pinEntered: pin,
      );

      state = state.copyWith(
        isLoading: false,
        contestFound: contest,
        isJoined: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> leaveLobby(String contestId) async {
    try {
      final user = ref.read(authStateProvider).asData?.value;
      if (user != null) {
        await ref.read(contestRepositoryProvider).leaveContest(
              contestId: contestId,
              participantId: user.id,
            );
      }
    } catch (_) {}
  }
}

final joinContestControllerProvider =
    NotifierProvider<JoinContestController, JoinContestState>(
  JoinContestController.new,
);
