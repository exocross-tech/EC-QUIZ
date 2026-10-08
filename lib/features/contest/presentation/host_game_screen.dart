import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizapp/core/constants/app_colors.dart';
import 'package:quizapp/features/contest/data/firestore_contest_repository.dart';
import 'package:quizapp/features/contest/domain/contest.dart';
import 'package:quizapp/features/contest/domain/contest_participant.dart';
import 'package:quizapp/features/contest/presentation/controllers/host_game_controller.dart';
import 'package:quizapp/features/contest/presentation/widgets/answer_distribution_chart.dart';
import 'package:quizapp/features/contest/presentation/widgets/leaderboard_view.dart';
import 'package:quizapp/features/contest/presentation/widgets/participant_avatar_card.dart';
import 'package:quizapp/features/contest/presentation/widgets/podium_view.dart';
import 'package:quizapp/core/widgets/question_image_gallery.dart';
import 'package:quizapp/features/contest/presentation/widgets/qr_code_dialog.dart';


class HostGameScreen extends ConsumerStatefulWidget {
  final String contestId;

  const HostGameScreen({
    super.key,
    required this.contestId,
  });

  @override
  ConsumerState<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends ConsumerState<HostGameScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _lastHandledQuestionIndex = -2;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _syncTimer(Contest contest) {
    if (contest.stage != ContestStage.questionActive) {
      _countdownTimer?.cancel();
      return;
    }

    if (contest.currentQuestionIndex != _lastHandledQuestionIndex) {
      _lastHandledQuestionIndex = contest.currentQuestionIndex;
      final timeLimit = contest.activeQuestion?.timeLimitSeconds ?? 20;

      if (contest.questionOpenedAt != null) {
        final elapsed = DateTime.now().difference(contest.questionOpenedAt!).inSeconds;
        _remainingSeconds = (timeLimit - elapsed).clamp(0, timeLimit);
      } else {
        _remainingSeconds = timeLimit;
      }

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final currentContest = ref.read(contestStreamProvider(widget.contestId)).asData?.value;
        if (currentContest?.isPaused == true) return;

        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final contestAsync = ref.watch(contestStreamProvider(widget.contestId));
    final participantsAsync = ref.watch(participantsStreamProvider(widget.contestId));
    final hostGameController = ref.read(hostGameControllerProvider.notifier);
    final hostGameState = ref.watch(hostGameControllerProvider);

    final contest = contestAsync.asData?.value;
    final isPodium = contest?.stage == ContestStage.podium;

    // Real-time departure detection: notify host if a player leaves during the game
    ref.listen<AsyncValue<List<ContestParticipant>>>(
      participantsStreamProvider(widget.contestId),
      (previous, next) {
        final prevList = previous?.asData?.value;
        final nextList = next.asData?.value;
        if (prevList != null && nextList != null) {
          final nextIds = nextList.map((p) => p.id).toSet();
          final currentContest = ref.read(contestStreamProvider(widget.contestId)).asData?.value;
          for (final p in prevList) {
            if (!nextIds.contains(p.id) && (currentContest?.kickedUserIds.contains(p.id) != true)) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.person_remove_outlined, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('${p.displayName} left the contest.'),
                    ],
                  ),
                  backgroundColor: Colors.black87,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          }
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          isPodium ? 'Final Podium 🏆' : (contest?.quizTitle ?? 'Live Contest'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: isPodium
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.qr_code_2),

                  tooltip: 'Show Join Code & QR',
                  onPressed: () {
                    if (contest != null) {
                      QrCodeDialog.show(
                        context: context,
                        joinCode: contest.joinCode,
                        quizTitle: contest.quizTitle,
                        pin: contest.pin,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.people_outline),
                  tooltip: 'View / Kick Players',
                  onPressed: () => _showPlayersModal(context),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'End Contest Early',
                  onPressed: () => _confirmEndContest(context),
                ),
              ],
      ),
      body: contestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading contest: $e')),
        data: (contest) {
          if (contest == null || (contest.status == ContestStatus.ended && contest.stage != ContestStage.podium)) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle_outline, size: 56, color: Colors.green),
                  const SizedBox(height: 12),
                  const Text('Contest has ended.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            );
          }

          // Trigger sync on active questions
          _syncTimer(contest);

          final participants = participantsAsync.asData?.value ?? [];

          // Render view according to stage
          switch (contest.stage) {
            case ContestStage.questionActive:
              return _buildQuestionActiveView(context, contest, participants, hostGameController, hostGameState);

            case ContestStage.answerReveal:
              return _buildAnswerRevealView(context, contest, participants, hostGameController, hostGameState);

            case ContestStage.leaderboard:
              return _buildLeaderboardView(context, contest, participants, hostGameController, hostGameState);

            case ContestStage.podium:
            case ContestStage.ended:
              return PodiumView(
                participants: participants,
                isHost: true,
                onFinish: () async {
                  await hostGameController.endContest(contest.id, endedReason: 'completed');
                  if (context.mounted) context.go('/home');
                },
              );

            case ContestStage.lobby:
            case ContestStage.starting:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // 1. QUESTION ACTIVE (HOST CONSOLE)
  Widget _buildQuestionActiveView(
    BuildContext context,
    Contest contest,
    List<dynamic> participants,
    HostGameController controller,
    HostGameState state,
  ) {
    final theme = Theme.of(context);
    final question = contest.activeQuestion;
    final totalPlayers = participants.length;
    final answered = contest.answersSubmittedCount;
    final timeLimit = question?.timeLimitSeconds ?? 20;
    final timerRatio = timeLimit > 0 ? (_remainingSeconds / timeLimit) : 0.0;

    final timerColor = _remainingSeconds <= 5
        ? AppColors.gameRed
        : (_remainingSeconds <= 10 ? AppColors.gameYellow : AppColors.accent);

    return SafeArea(
      child: Column(
        children: [
          // Question Header Info
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Question ${contest.currentQuestionIndex + 1} of ${contest.questionsCount}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => controller.togglePause(contest),
                  icon: Icon(contest.isPaused ? Icons.play_arrow : Icons.pause),
                  tooltip: contest.isPaused ? 'Resume Timer' : 'Pause Timer',
                ),
              ],
            ),
          ),

          // Central Question & Live Ring
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  // Timer Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: timerRatio,
                          strokeWidth: 8,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_remainingSeconds',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: timerColor,
                            ),
                          ),
                          const Text('sec', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Question Text
                  Text(
                    question?.text ?? 'Question',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),

                  // Optional Image(s)
                  if (question != null && question.imagesBase64.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    QuestionImageGallery(imagesBase64: question.imagesBase64),
                  ],
                  const SizedBox(height: 20),

                  // Answers submitted progress meter
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Player Responses',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              '$answered / $totalPlayers answered',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: answered == totalPlayers && totalPlayers > 0
                                    ? AppColors.gameGreen
                                    : AppColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: totalPlayers > 0 ? (answered / totalPlayers) : 0.0,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(6),
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            answered == totalPlayers && totalPlayers > 0
                                ? AppColors.gameGreen
                                : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Host Reveal Controls Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isLoading
                    ? null
                    : () => controller.revealAnswers(
                          contest: contest,
                          participants: participants.cast(),
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gameBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.visibility),
                label: Text(
                  _remainingSeconds == 0 || (answered >= totalPlayers && totalPlayers > 0)
                      ? 'Reveal Answers'
                      : 'End Timer & Reveal ($answered/$totalPlayers ready)',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 2. ANSWER REVEAL (HOST VIEW)
  Widget _buildAnswerRevealView(
    BuildContext context,
    Contest contest,
    List<dynamic> participants,
    HostGameController controller,
    HostGameState state,
  ) {
    final theme = Theme.of(context);
    final question = contest.activeQuestion;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question banner
                  Text(
                    'Q${contest.currentQuestionIndex + 1}: ${question?.text ?? ""}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Distribution chart
                  if (question != null)
                    AnswerDistributionChart(
                      options: question.options,
                      correctAnswers: question.correctAnswers,
                      distribution: contest.answerDistribution,
                      questionType: question.type,
                    ),

                  // Explanation card if available
                  if (question?.explanation != null && question!.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Explanation',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                ),
                                const SizedBox(height: 4),
                                Text(question.explanation!, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Next: Leaderboard Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.showLeaderboard(contest.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.leaderboard),
                label: const Text(
                  'Show Leaderboard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 3. LEADERBOARD (HOST VIEW)
  Widget _buildLeaderboardView(
    BuildContext context,
    Contest contest,
    List<dynamic> participants,
    HostGameController controller,
    HostGameState state,
  ) {
    final theme = Theme.of(context);
    final isLastQuestion = contest.currentQuestionIndex + 1 >= contest.questionsCount;

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
                const SizedBox(width: 8),
                Text(
                  'Scoreboard (Round ${contest.currentQuestionIndex + 1})',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: LeaderboardView(
                participants: participants.cast(),
                isHost: true,
              ),
            ),
          ),

          // Advance Question Bottom Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.isLoading ? null : () => controller.nextQuestion(contest),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isLastQuestion ? AppColors.gameYellow : AppColors.gameGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(isLastQuestion ? Icons.military_tech : Icons.arrow_forward_rounded),
                label: Text(
                  isLastQuestion ? 'Final Podium 🏆' : 'Next Question (${contest.currentQuestionIndex + 2}/${contest.questionsCount})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlayersModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, _) {
            final playersAsync = ref.watch(participantsStreamProvider(widget.contestId));
            final hostRepo = ref.read(contestRepositoryProvider);

            return Material(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Live Participants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    playersAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('Error: $e'),
                      data: (players) {
                        if (players.isEmpty) return const Text('No players connected.');
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: players.map((p) {
                            return ParticipantAvatarCard(
                              participant: p,
                              isHostView: true,
                              onKick: () async {
                                await hostRepo.kickParticipant(contestId: widget.contestId, participantId: p.id);
                              },
                            );
                          }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmEndContest(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Contest?'),
        content: const Text('Are you sure you want to end the contest early for all players?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gameRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End Contest', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(hostGameControllerProvider.notifier).endContest(widget.contestId, endedReason: 'host_left');
      if (context.mounted) context.go('/home');
    }
  }
}
