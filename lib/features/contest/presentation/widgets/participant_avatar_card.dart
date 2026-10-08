import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/avatar_display.dart';
import '../../domain/contest_participant.dart';

class ParticipantAvatarCard extends StatelessWidget {
  final ContestParticipant participant;
  final bool isHostView;
  final VoidCallback? onKick;

  const ParticipantAvatarCard({
    super.key,
    required this.participant,
    this.isHostView = false,
    this.onKick,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AvatarDisplay(
            avatarType: participant.avatarType,
            avatarPresetId: participant.avatarPresetId,
            avatarColor: participant.avatarColor,
            avatarBase64: participant.avatarBase64,
            radius: 18,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              participant.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isHostView && onKick != null) ...[
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: AppColors.gameRed, size: 20),
              tooltip: 'Kick ${participant.displayName}',
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: () => _confirmKick(context),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmKick(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kick Player'),
        content: Text('Are you sure you want to kick "${participant.displayName}" from this contest?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gameRed),
            onPressed: () {
              Navigator.of(ctx).pop();
              onKick?.call();
            },
            child: const Text('Kick Player', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
