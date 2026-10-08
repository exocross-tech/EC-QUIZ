import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizapp/core/constants/app_colors.dart';
import 'package:quizapp/core/services/sound_service.dart';
import 'package:quizapp/core/widgets/avatar_display.dart';
import 'package:quizapp/core/widgets/confetti_overlay.dart';
import 'package:quizapp/features/contest/domain/contest_participant.dart';

class PodiumView extends ConsumerStatefulWidget {
  final List<ContestParticipant> participants;
  final VoidCallback onFinish;
  final bool isHost;

  const PodiumView({
    super.key,
    required this.participants,
    required this.onFinish,
    this.isHost = false,
  });

  @override
  ConsumerState<PodiumView> createState() => _PodiumViewState();
}

class _PodiumViewState extends ConsumerState<PodiumView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(soundServiceProvider).playFanfare();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sorted descending by total score
    final sorted = List<ContestParticipant>.from(widget.participants)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    final first = sorted.isNotEmpty ? sorted[0] : null;
    final second = sorted.length > 1 ? sorted[1] : null;
    final third = sorted.length > 2 ? sorted[2] : null;
    final rest = sorted.length > 3 ? sorted.sublist(3) : <ContestParticipant>[];

    return ConfettiOverlay(
      child: SingleChildScrollView(

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          // Celebration Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('🎉', style: TextStyle(fontSize: 26)),
                SizedBox(width: 8),
                Text(
                  'FINAL PODIUM',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                SizedBox(width: 8),
                Text('🏆', style: TextStyle(fontSize: 26)),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // 3-Step Podium Display
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 2nd Place (Left)
              Expanded(
                child: _buildPodiumStep(
                  context: context,
                  participant: second,
                  place: 2,
                  height: 120,
                  color: const Color(0xFFC0C0C0),
                  medal: '🥈',
                ),
              ),
              const SizedBox(width: 8),

              // 1st Place (Center - Tallest)
              Expanded(
                child: _buildPodiumStep(
                  context: context,
                  participant: first,
                  place: 1,
                  height: 170,
                  color: const Color(0xFFFFD700),
                  medal: '🏆',
                  isWinner: true,
                ),
              ),
              const SizedBox(width: 8),

              // 3rd Place (Right)
              Expanded(
                child: _buildPodiumStep(
                  context: context,
                  participant: third,
                  place: 3,
                  height: 90,
                  color: const Color(0xFFCD7F32),
                  medal: '🥉',
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Runners up list (4th place and below)
          if (rest.isNotEmpty) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Other Participants',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...rest.asMap().entries.map((entry) {
              final rank = entry.key + 4;
              final p = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                ),
                child: Row(
                  children: [
                    Text(
                      '#$rank',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 12),
                    AvatarDisplay(
                      avatarType: p.avatarType,
                      avatarPresetId: p.avatarPresetId,
                      avatarColor: p.avatarColor,
                      avatarBase64: p.avatarBase64,
                      radius: 16,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        p.displayName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${p.totalScore} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 24),
          ],

          // Finish / Home Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: widget.onFinish,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.home_rounded),
              label: Text(
                widget.isHost ? 'End Contest & Return Home' : 'Back to Home',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildPodiumStep({
    required BuildContext context,
    required ContestParticipant? participant,
    required int place,
    required double height,
    required Color color,
    required String medal,
    bool isWinner = false,
  }) {
    if (participant == null) {
      return Column(
        children: [
          Container(
            height: height,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Text(
                '#$place',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Medal & Avatar
        Text(medal, style: TextStyle(fontSize: isWinner ? 32 : 24)),
        const SizedBox(height: 4),
        AvatarDisplay(
          avatarType: participant.avatarType,
          avatarPresetId: participant.avatarPresetId,
          avatarColor: participant.avatarColor,
          avatarBase64: participant.avatarBase64,
          radius: isWinner ? 28 : 22,
        ),
        const SizedBox(height: 6),
        Text(
          participant.displayName,
          style: TextStyle(
            fontSize: isWinner ? 14 : 12,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        Text(
          '${participant.totalScore} pts',
          style: TextStyle(
            fontSize: isWinner ? 13 : 11,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 8),

        // The Podium Pedestal Block
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withValues(alpha: 0.8),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$place',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
