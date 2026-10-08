import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../data/firestore_contest_repository.dart';
import '../domain/contest.dart';
import 'controllers/host_game_controller.dart';
import 'host_contest_controller.dart';
import 'host_game_screen.dart';
import 'widgets/participant_avatar_card.dart';
import 'widgets/qr_code_dialog.dart';

class HostLobbyScreen extends ConsumerWidget {
  final String contestId;

  const HostLobbyScreen({
    super.key,
    required this.contestId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contestAsync = ref.watch(contestStreamProvider(contestId));
    final participantsAsync = ref.watch(participantsStreamProvider(contestId));
    final hostController = ref.read(hostContestControllerProvider.notifier);

    // If game has started, return HostGameScreen directly (single navbar, no nested Scaffold)
    final contest = contestAsync.asData?.value;
    if (contest != null && contest.status == ContestStatus.inProgress) {
      return HostGameScreen(contestId: contestId);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Lobby (Host)', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          contestAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
            data: (contest) {
              if (contest == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.qr_code_2),
                tooltip: 'Show QR Code',
                onPressed: () => QrCodeDialog.show(
                  context: context,
                  joinCode: contest.joinCode,
                  quizTitle: contest.quizTitle,
                  pin: contest.pin,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'End Contest',
            onPressed: () => _confirmEndContest(context, ref),
          ),
        ],
      ),
      body: contestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading contest: $e')),
        data: (contest) {
          if (contest == null || contest.status == ContestStatus.ended) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('This contest has ended.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            );
          }

          // Transition to live game screen once started
          if (contest.status == ContestStatus.inProgress) {
            return HostGameScreen(contestId: contestId);
          }

          return SafeArea(
            child: Column(
              children: [
                // Top Hero Card with Join Code
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryContainer],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        contest.quizTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${contest.questionsCount} Questions • Kahoot Speed Scoring',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // 6-Character Code Box
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: contest.joinCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Code ${contest.joinCode} copied!'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                contest.joinCode,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 6,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.copy, color: AppColors.primary, size: 20),
                            ],
                          ),
                        ),
                      ),

                      if (contest.hasPin) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'PIN Required: ${contest.pin}',
                            style: const TextStyle(
                              color: Colors.amberAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Participants Section Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.people_alt_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Players in Lobby',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      participantsAsync.when(
                        loading: () => const Text('Loading...'),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (players) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${players.length} / ${contest.maxParticipants}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Live Participants List
                Expanded(
                  child: participantsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error loading players: $e')),
                    data: (players) {
                      if (players.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.hourglass_empty_rounded,
                                  size: 48,
                                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Waiting for players...',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Share the join code or QR code with your friends to start.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: players.map((player) {
                            return ParticipantAvatarCard(
                              participant: player,
                              isHostView: true,
                              onKick: () => hostController.kickPlayer(
                                contestId: contest.id,
                                participantId: player.id,
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),

                // Host Controls Bottom Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
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
                  child: participantsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (players) {
                      final hasPlayers = players.isNotEmpty;

                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: hasPlayers
                                  ? () async {
                                      final success = await ref
                                          .read(hostGameControllerProvider.notifier)
                                          .startLiveGame(
                                            contestId: contest.id,
                                            quizId: contest.quizId,
                                          );
                                      if (!success && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Failed to start contest. Check that the quiz has questions.'),
                                            backgroundColor: AppColors.gameRed,
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.gameGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: Text(
                                hasPlayers ? 'Start Contest' : 'Waiting for Players...',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmEndContest(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('End Contest?'),
        content: const Text(
          'Are you sure you want to cancel and end this contest? The lobby will be closed for all players.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Open'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gameRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('End Contest', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(hostContestControllerProvider.notifier).cancelContest(contestId);
      if (context.mounted) {
        context.go('/home');
      }
    }
  }
}
