import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/sound_toggle_button.dart';
import '../../auth/domain/app_user.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../contest/presentation/create_contest_dialog.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _promptGuestAuth(BuildContext context, {required String actionTitle}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionTitle Requires Account'),
        content: const Text(
          'To create custom quizzes, upload questions, and host live game lobbies for other players, please create a free Quiz Clash account or sign in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gameRed),
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/login');
            },
            child: const Text('Sign In / Register', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.w900),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          const SoundToggleButton(),
          profileAsync.maybeWhen(

            data: (profile) {
              if (profile != null) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => context.push('/profile'),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: AvatarDisplay(
                        avatarType: profile.avatarType,
                        avatarPresetId: profile.avatarPresetId,
                        avatarColor: profile.avatarColor,
                        avatarBase64: profile.avatarBase64,
                        radius: 17,
                      ),
                    ),
                  ),
                );
              }
              return IconButton(
                tooltip: 'View Profile',
                icon: const Icon(Icons.person),
                onPressed: () => context.push('/profile'),
              );
            },
            orElse: () => IconButton(
              tooltip: 'View Profile',
              icon: const Icon(Icons.person),
              onPressed: () => context.push('/profile'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // User Hero Header Card
              profileAsync.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (err, _) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading profile: $err'),
                  ),
                ),
                data: (profile) {
                  if (profile == null) {
                    final guest = ref.watch(effectiveUserProvider);
                    if (guest != null) {
                      return _buildGuestHeader(context, guest);
                    }
                    return const SizedBox.shrink();
                  }

                  return GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryContainer],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          AvatarDisplay(
                            avatarType: profile.avatarType,
                            avatarPresetId: profile.avatarPresetId,
                            avatarColor: profile.avatarColor,
                            avatarBase64: profile.avatarBase64,
                            radius: 30,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ready to play,',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  profile.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    _buildPill(
                                      '🏆 ${profile.totalPoints} pts',
                                      Colors.amber.shade300,
                                    ),
                                    _buildPill(
                                      '🥇 ${profile.wins} wins',
                                      Colors.lightGreenAccent.shade100,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),

              // Game Modes Section
              Text(
                'Live Contest Central',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),

              // Join Contest Card (Kahoot style)
              _buildActionCard(
                context,
                title: 'Join a Contest',
                subtitle: 'Enter 6-character code or scan QR',
                icon: Icons.pin,
                color: AppColors.gameRed,
                buttonText: 'Join Game',
                onTap: () => context.push('/contests/join'),
              ),
              const SizedBox(height: 14),

              // Host Contest Card
              _buildActionCard(
                context,
                title: 'Host Live Contest',
                subtitle: 'Launch a game session with real-time scoring',
                icon: Icons.sensors,
                color: AppColors.gameBlue,
                buttonText: 'Host Contest',
                onTap: () {
                  final isGuest = ref.read(currentUserProfileProvider).asData?.value == null;
                  if (isGuest) {
                    _promptGuestAuth(context, actionTitle: 'Hosting Live Contests');
                  } else {
                    CreateContestDialog.show(context: context);
                  }
                },
              ),
              const SizedBox(height: 14),

              // Quiz Builder Card
              _buildActionCard(
                context,
                title: 'Quiz Studio & Builder',
                subtitle: 'Create questions, compressed images, and timer rules',
                icon: Icons.quiz_outlined,
                color: AppColors.gameGreen,
                buttonText: 'Open Quiz Studio',
                onTap: () {
                  final isGuest = ref.read(currentUserProfileProvider).asData?.value == null;
                  if (isGuest) {
                    _promptGuestAuth(context, actionTitle: 'Quiz Studio');
                  } else {
                    context.push('/quizzes');
                  }
                },
              ),
              const SizedBox(height: 14),

              // Solo Practice Card
              _buildActionCard(
                context,
                title: 'Solo Practice Mode',
                subtitle: 'Play against time without a live host',
                icon: Icons.speed,
                color: AppColors.gameYellow,
                buttonText: 'Start Practice',
                onTap: () => context.push('/practice'),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPill(String text, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestHeader(BuildContext context, AppUser guest) {
    final displayName = guest.displayName?.isNotEmpty == true
        ? guest.displayName!
        : 'Guest Player';

    return GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.gameRed, Color(0xFFC01633)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.gameRed.withValues(alpha: 0.3),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const AvatarDisplay(
              avatarType: 'preset',
              avatarPresetId: 'lion',
              avatarColor: '#E21B3C',
              radius: 30,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome to Quiz Clash,',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildPill(
                        '🎮 Guest Mode',
                        Colors.amber.shade200,
                      ),
                      _buildPill(
                        'Tap to Sign Up',
                        Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
