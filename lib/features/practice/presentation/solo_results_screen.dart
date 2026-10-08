import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/sound_service.dart';
import '../../../core/widgets/confetti_overlay.dart';
import '../../../core/widgets/sound_toggle_button.dart';
import 'solo_game_controller.dart';

class SoloResultsScreen extends ConsumerStatefulWidget {
  const SoloResultsScreen({super.key});

  @override
  ConsumerState<SoloResultsScreen> createState() => _SoloResultsScreenState();
}

class _SoloResultsScreenState extends ConsumerState<SoloResultsScreen> {
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
    final state = ref.watch(soloGameControllerProvider);
    final controller = ref.read(soloGameControllerProvider.notifier);

    final quiz = state.quiz;
    final totalQuestions = state.totalQuestions;
    final totalCorrect = state.totalCorrect;
    final accuracy = state.accuracyPercent;
    final score = state.score;
    final maxStreak = state.highestStreak;
    final avgSpeed = state.averageResponseTime;

    // Headline badge & subtitle
    final String headline;
    final Color badgeColor;
    final IconData badgeIcon;
    if (accuracy == 100) {
      headline = 'PERFECT SCORE!';
      badgeColor = const Color(0xFFFFD700);
      badgeIcon = Icons.stars_rounded;
    } else if (accuracy >= 80) {
      headline = 'OUTSTANDING!';
      badgeColor = AppColors.gameGreen;
      badgeIcon = Icons.emoji_events_rounded;
    } else if (accuracy >= 50) {
      headline = 'GREAT EFFORT!';
      badgeColor = AppColors.gameBlue;
      badgeIcon = Icons.thumb_up_rounded;
    } else {
      headline = 'KEEP PRACTICING!';
      badgeColor = AppColors.gameYellow;
      badgeIcon = Icons.fitness_center_rounded;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Practice Summary'),
        automaticallyImplyLeading: false,
        actions: [
          const SoundToggleButton(),
          IconButton(
            tooltip: 'Home',
            icon: const Icon(Icons.home_rounded),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: ConfettiOverlay(
        autoPlay: accuracy >= 50,
        child: SingleChildScrollView(

        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Celebration Banner
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    badgeColor.withValues(alpha: 0.85),
                    badgeColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(badgeIcon, size: 54, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    headline,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    quiz?.title ?? 'Solo Practice Quiz',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🏆 $score Total Points',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Performance Metrics Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Accuracy',
                    value: '$accuracy%',
                    subValue: '$totalCorrect / $totalQuestions correct',
                    icon: Icons.check_circle_outline_rounded,
                    color: AppColors.gameGreen,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Highest Streak',
                    value: '$maxStreak 🔥',
                    subValue: 'in a row',
                    icon: Icons.local_fire_department_rounded,
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Avg Speed',
                    value: '${avgSpeed.toStringAsFixed(1)}s',
                    subValue: 'per question',
                    icon: Icons.speed_rounded,
                    color: AppColors.gameBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    title: 'Questions',
                    value: '$totalQuestions',
                    subValue: 'completed',
                    icon: Icons.format_list_numbered_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Question Review Header
            Row(
              children: [
                const Icon(Icons.rate_review_rounded, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Detailed Question Review',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Question List
            ...List.generate(state.history.length, (index) {
              final item = state.history[index];
              return _buildReviewCard(context, item, index + 1);
            }),
            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                controller.restartGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gameGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
              icon: const Icon(Icons.replay_rounded, size: 22),
              label: const Text(
                'Play Again',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                context.go('/practice');
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              icon: const Icon(Icons.explore_rounded, color: AppColors.primary),
              label: const Text(
                'Choose Another Quiz',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {
                context.go('/home');
              },
              icon: const Icon(Icons.home_outlined),
              label: const Text('Back to Home'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  );
}


  Widget _buildMetricCard(
    ThemeData theme, {
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subValue,
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, dynamic item, int index) {
    final theme = Theme.of(context);
    final isCorrect = item.isCorrect;
    final statusColor = isCorrect ? AppColors.gameGreen : AppColors.gameRed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    color: statusColor,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Question $index',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            isCorrect
                                ? '+${item.pointsAwarded} pts'
                                : '+0 pts',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.question.text,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Answers Breakdown
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your answer: ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Expanded(
                  child: Text(
                    item.formattedUserAnswer,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCorrect ? AppColors.gameGreen : AppColors.gameRed,
                    ),
                  ),
                ),
              ],
            ),

            if (!isCorrect) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Correct answer: ',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: Text(
                      item.formattedCorrectAnswer,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.gameGreen,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            // Explanation (if present)
            if (item.question.explanation != null &&
                item.question.explanation!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.question.explanation!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
