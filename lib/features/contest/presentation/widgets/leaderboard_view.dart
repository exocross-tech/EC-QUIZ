import 'package:flutter/material.dart';
import 'package:quizapp/core/constants/app_colors.dart';
import 'package:quizapp/core/widgets/avatar_display.dart';
import 'package:quizapp/features/contest/domain/contest_participant.dart';

class LeaderboardView extends StatelessWidget {
  final List<ContestParticipant> participants;
  final String? currentUserId;
  final bool isHost;

  const LeaderboardView({
    super.key,
    required this.participants,
    this.currentUserId,
    this.isHost = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Sorted descending by totalScore
    final sorted = List<ContestParticipant>.from(participants)
      ..sort((a, b) => b.totalScore.compareTo(a.totalScore));

    if (sorted.isEmpty) {
      return const Center(
        child: Text('No participants on the leaderboard yet.'),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final participant = sorted[index];
        final rank = index + 1;
        final isMe = participant.id == currentUserId;

        Widget rankWidget;

        if (rank == 1) {
          rankWidget = const Text('🥇', style: TextStyle(fontSize: 22));
        } else if (rank == 2) {
          rankWidget = const Text('🥈', style: TextStyle(fontSize: 22));
        } else if (rank == 3) {
          rankWidget = const Text('🥉', style: TextStyle(fontSize: 22));
        } else {
          rankWidget = Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isMe
                ? AppColors.primary.withValues(alpha: 0.1)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isMe
                  ? AppColors.primary
                  : Colors.grey.withValues(alpha: 0.15),
              width: isMe ? 2 : 1,
            ),
            boxShadow: isMe
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(width: 34, child: Center(child: rankWidget)),
              const SizedBox(width: 10),

              // Avatar
              AvatarDisplay(
                avatarType: participant.avatarType,
                avatarPresetId: participant.avatarPresetId,
                avatarColor: participant.avatarColor,
                avatarBase64: participant.avatarBase64,
                radius: 20,
              ),
              const SizedBox(width: 12),

              // Name & Streaks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            participant.displayName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isMe ? FontWeight.bold : FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMe) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'YOU',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (participant.streak >= 2)
                          Text(
                            '🔥 ${participant.streak} streak',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange,
                            ),
                          ),
                        if (participant.lastPointsEarned > 0)
                          Text(
                            '+${participant.lastPointsEarned} pts',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.gameGreen,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Total Score
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${participant.totalScore}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
