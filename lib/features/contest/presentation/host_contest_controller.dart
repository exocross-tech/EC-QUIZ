import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../quiz/domain/quiz.dart';
import '../data/firestore_contest_repository.dart';
import '../domain/contest.dart';

class HostContestController extends Notifier<AsyncValue<Contest?>> {
  @override
  AsyncValue<Contest?> build() {
    return const AsyncValue.data(null);
  }

  Future<Contest?> createAndLaunchContest({
    required Quiz quiz,
    String? pin,
    int maxParticipants = 20,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = ref.read(authStateProvider).asData?.value;
      final profile = ref.read(currentUserProfileProvider).asData?.value;

      if (user == null) {
        throw Exception('Must be signed in to host a contest.');
      }

      final repo = ref.read(contestRepositoryProvider);
      final contest = await repo.createContest(
        quiz: quiz,
        hostId: user.id,
        hostName: profile?.displayName ?? user.displayName ?? 'Host',
        pin: pin,
        maxParticipants: maxParticipants,
      );

      state = AsyncValue.data(contest);
      return contest;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  Future<bool> kickPlayer({
    required String contestId,
    required String participantId,
  }) async {
    try {
      final repo = ref.read(contestRepositoryProvider);
      await repo.kickParticipant(
        contestId: contestId,
        participantId: participantId,
      );
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> startContest(String contestId) async {
    try {
      final repo = ref.read(contestRepositoryProvider);
      await repo.updateContestStatus(
        contestId: contestId,
        status: ContestStatus.inProgress,
      );
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> cancelContest(String contestId) async {
    try {
      final repo = ref.read(contestRepositoryProvider);
      await repo.endContest(contestId, endedReason: 'host_left');
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final hostContestControllerProvider =
    NotifierProvider<HostContestController, AsyncValue<Contest?>>(
  HostContestController.new,
);
