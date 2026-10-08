import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/custom_button.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/services/sound_service.dart';
import 'edit_profile_dialog.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    final effectiveUser = ref.read(effectiveUserProvider);
    final isGuest = effectiveUser?.isAnonymous == true ||
        (effectiveUser?.uid.startsWith('guest_') ?? false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isGuest ? 'Exit Guest Mode' : 'Log Out'),
        content: Text(
          isGuest
              ? 'Are you sure you want to exit your guest session? Any temporary nickname will be reset.'
              : 'Are you sure you want to log out of Quiz Clash?',
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
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: Text(
              isGuest ? 'Exit Guest Mode' : 'Log Out',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentUserProfileProvider);
    final theme = Theme.of(context);
    final currentThemeMode = ref.watch(themeModeControllerProvider);
    final isDarkMode = currentThemeMode == ThemeMode.dark;
    final isSoundEnabled = ref.watch(soundSettingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile & Stats', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Log Out',
            icon: const Icon(Icons.logout),
            onPressed: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.gameRed),
                const SizedBox(height: 12),
                Text('Failed to load profile: $err', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            final guest = ref.watch(effectiveUserProvider);
            if (guest != null) {
              return _buildGuestProfile(context, ref, guest, theme, isDarkMode);
            }
            return const Center(child: Text('No profile found. Please sign in.'));
          }

          final winRate = profile.contestsPlayed > 0
              ? '${((profile.wins / profile.contestsPlayed) * 100).toStringAsFixed(0)}%'
              : '0%';

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                // Avatar & Name Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Column(
                      children: [
                        AvatarDisplay(
                          avatarType: profile.avatarType,
                          avatarPresetId: profile.avatarPresetId,
                          avatarColor: profile.avatarColor,
                          avatarBase64: profile.avatarBase64,
                          radius: 50,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          profile.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.email,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 18),
                        OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => EditProfileDialog(profile: profile),
                            );
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text('Edit Persona / Photo'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Statistics Section Header
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Contest Statistics',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    _buildStatCard(
                      context,
                      title: 'Contests Played',
                      value: profile.contestsPlayed.toString(),
                      icon: Icons.sports_esports,
                      color: AppColors.gameBlue,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Total Points',
                      value: profile.totalPoints.toString(),
                      icon: Icons.emoji_events,
                      color: AppColors.gameYellow,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Victories',
                      value: profile.wins.toString(),
                      icon: Icons.military_tech,
                      color: AppColors.gameGreen,
                    ),
                    _buildStatCard(
                      context,
                      title: 'Win Rate',
                      value: winRate,
                      icon: Icons.pie_chart,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Sound Effects & Audio Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSoundEnabled
                                ? AppColors.gameGreen.withValues(alpha: 0.18)
                                : Colors.grey.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                            color: isSoundEnabled ? AppColors.gameGreen : Colors.grey,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sound Effects & Audio',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isSoundEnabled
                                    ? 'Sound effects & music active'
                                    : 'Sound muted',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isSoundEnabled,
                          activeTrackColor: AppColors.gameGreen,
                          thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Icon(Icons.volume_up, size: 16, color: Colors.white);
                            }
                            return const Icon(Icons.volume_off, size: 16, color: Colors.grey);
                          }),
                          onChanged: (val) {
                            ref.read(soundSettingProvider.notifier).setSound(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Theme Preference Card
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? AppColors.primary.withValues(alpha: 0.2)
                                : AppColors.gameYellow.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDarkMode ? Icons.dark_mode : Icons.light_mode,
                            color: isDarkMode ? AppColors.primaryContainer : AppColors.gameYellow,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Theme Preference',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isDarkMode ? 'Dark Theme active' : 'Light Theme active',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isDarkMode,
                          activeTrackColor: AppColors.primary,
                          thumbIcon: WidgetStateProperty.resolveWith<Icon?>((states) {
                            if (states.contains(WidgetState.selected)) {
                              return const Icon(Icons.dark_mode, size: 16, color: Colors.white);
                            }
                            return const Icon(Icons.light_mode, size: 16, color: Colors.amber);
                          }),
                          onChanged: (val) {
                            ref
                                .read(themeModeControllerProvider.notifier)
                                .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Log out button
                CustomButton(
                  label: 'Log Out',
                  isOutlined: true,
                  backgroundColor: AppColors.gameRed,
                  icon: Icons.logout,
                  onPressed: () => _showSignOutDialog(context, ref),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              CircleAvatar(
                radius: 14,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestProfile(
    BuildContext context,
    WidgetRef ref,
    AppUser guestUser,
    ThemeData theme,
    bool isDarkMode,
  ) {
    final displayName = guestUser.displayName?.isNotEmpty == true
        ? guestUser.displayName!
        : 'Guest Player';
    final isSoundEnabled = ref.watch(soundSettingProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Guest Persona Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  const AvatarDisplay(
                    avatarType: 'preset',
                    avatarPresetId: 'lion',
                    avatarColor: '#E21B3C',
                    radius: 50,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.gameYellow.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.gameYellow.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.sports_esports, size: 14, color: AppColors.gameYellow),
                        SizedBox(width: 6),
                        Text(
                          'Temporary Guest Session',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gameYellow,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'You are playing without a permanent Quiz Clash account. Scores in active live games are saved for that contest, but career stats, trophies, and quiz creation require an account.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // CTA Buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/register'),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Create Free Account'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gameRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/login'),
                      icon: const Icon(Icons.login),
                      label: const Text('Sign In to Existing Account'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sound Settings Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                        color: isSoundEnabled ? AppColors.gameGreen : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Sound Effects & Audio',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isSoundEnabled,
                    activeTrackColor: AppColors.gameGreen,
                    onChanged: (val) {
                      ref.read(soundSettingProvider.notifier).setSound(val);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Theme Settings Card
          Card(
            elevation: 0,
            color: theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Dark Theme',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Switch(
                    value: isDarkMode,
                    onChanged: (val) {
                      ref
                          .read(themeModeControllerProvider.notifier)
                          .setThemeMode(val ? ThemeMode.dark : ThemeMode.light);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Exit Guest Session button
          CustomButton(
            label: 'Exit Guest Mode',
            isOutlined: true,
            backgroundColor: AppColors.gameRed,
            icon: Icons.logout,
            onPressed: () => _showSignOutDialog(context, ref),
          ),
        ],
      ),
    );
  }
}
