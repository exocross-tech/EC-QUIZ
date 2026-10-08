import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'auth_controller.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedEmojiId = 'lion';
  Color _selectedColor = AppColors.avatarColors[0];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    final success = await ref.read(authControllerProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
          avatarPresetId: _selectedEmojiId,
          avatarColor: colorHex,
        );

    if (!success && mounted) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error?.toString().replaceAll('Exception: ', '') ??
                'Registration failed. Please try again.',
          ),
          backgroundColor: AppColors.gameRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (mounted) {
      // Successfully registered, go to home
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account', overflow: TextOverflow.ellipsis),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Avatar preview & customization header
                Center(
                  child: Column(
                    children: [
                      AvatarDisplay(
                        avatarType: 'preset',
                        avatarPresetId: _selectedEmojiId,
                        avatarColor:
                            '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
                        radius: 44,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose Your Game Persona',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.grey.shade700,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Horizontal list of preset avatars
                SizedBox(
                  height: 52,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppConstants.defaultAvatarPresets.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final preset = AppConstants.defaultAvatarPresets[index];
                      final isSelected = _selectedEmojiId == preset.id;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedEmojiId = preset.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              preset.emoji,
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Color selector for the badge
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: AppColors.avatarColors.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final color = AppColors.avatarColors[index];
                      final isSelected = _selectedColor == color;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColor = color),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withValues(alpha: 0.6),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 20)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Display Name Input
                CustomTextField(
                  controller: _nameController,
                  label: 'Display Name / Nickname',
                  hint: 'e.g., QuizMaster99',
                  prefixIcon: Icons.badge_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Display name is required';
                    }
                    if (val.trim().length < 2) {
                      return 'Must be at least 2 characters';
                    }
                    if (val.trim().length > 25) {
                      return 'Must be 25 characters or less';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email Input
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hint: 'your.name@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Input
                CustomTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'At least 6 characters',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password is required';
                    }
                    if (val.length < 6) {
                      return 'Must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password Input
                CustomTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Re-enter password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // Sign Up Button
                CustomButton(
                  label: 'Create Account',
                  isLoading: isLoading,
                  icon: Icons.person_add_alt_1,
                  onPressed: _handleRegister,
                ),
                const SizedBox(height: 20),

                // Back to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : () => context.pop(),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
