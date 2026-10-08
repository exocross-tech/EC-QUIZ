import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import 'join_contest_controller.dart';

class JoinContestScreen extends ConsumerStatefulWidget {
  const JoinContestScreen({super.key});

  @override
  ConsumerState<JoinContestScreen> createState() => _JoinContestScreenState();
}

class _JoinContestScreenState extends ConsumerState<JoinContestScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(joinContestControllerProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final controller = ref.read(joinContestControllerProvider.notifier);
    final state = ref.read(joinContestControllerProvider);

    if (state.needsPin) {
      final pin = _pinController.text.trim();
      if (pin.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter the contest PIN.'),
            backgroundColor: AppColors.gameRed,
          ),
        );
        return;
      }
      final success = await controller.submitPinAndJoin(pin);
      if (success && mounted) {
        final contestId = ref.read(joinContestControllerProvider).contestFound?.id;
        if (contestId != null) {
          context.pushReplacement('/contests/play/$contestId');
        }
      }
    } else {
      final code = _codeController.text.trim();
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a 6-character join code.'),
            backgroundColor: AppColors.gameRed,
          ),
        );
        return;
      }
      final contest = await controller.submitCode(code);
      if (contest != null && mounted) {
        final updatedState = ref.read(joinContestControllerProvider);
        if (!updatedState.needsPin && updatedState.isJoined) {
          context.pushReplacement('/contests/play/${contest.id}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(joinContestControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Join a Contest', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),

              // Hero Graphic / Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.gameRed.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.pin, size: 44, color: AppColors.gameRed),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Heading
              Text(
                state.needsPin ? 'Enter Contest PIN' : 'Enter 6-Character Join Code',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                state.needsPin
                    ? 'This host requires a PIN to join "${state.contestFound?.quizTitle}".'
                    : 'Ask the host for the 6-character code or scan their QR code.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Code Input (or PIN input if needed)
              if (!state.needsPin)
                TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    color: AppColors.gameRed,
                  ),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'CODE',
                    hintStyle: TextStyle(
                      color: Colors.grey.withValues(alpha: 0.4),
                      letterSpacing: 8,
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.gameRed, width: 2),
                    ),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _handleJoin(),
                )
              else
                TextField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                  ),
                  maxLength: 6,
                  decoration: InputDecoration(
                    hintText: 'PIN',
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    counterText: '',
                  ),
                  onSubmitted: (_) => _handleJoin(),
                ),

              // Error display
              if (state.errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gameRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: AppColors.gameRed, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Join Button
              ElevatedButton.icon(
                onPressed: state.isLoading ? null : _handleJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gameRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_forward_rounded),
                label: Text(
                  state.isLoading
                      ? 'Joining Lobby...'
                      : (state.needsPin ? 'Confirm PIN & Enter' : 'Enter Lobby'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),

              if (state.needsPin) ...[
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    ref.read(joinContestControllerProvider.notifier).reset();
                    _pinController.clear();
                  },
                  child: const Text('Back to Code Entry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
