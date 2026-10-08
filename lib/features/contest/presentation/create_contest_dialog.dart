import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../quiz/domain/quiz.dart';
import '../../quiz/presentation/quiz_list_controller.dart';
import 'host_contest_controller.dart';

class CreateContestDialog extends ConsumerStatefulWidget {
  final Quiz? initialQuiz;

  const CreateContestDialog({
    super.key,
    this.initialQuiz,
  });

  static Future<void> show({
    required BuildContext context,
    Quiz? initialQuiz,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CreateContestDialog(initialQuiz: initialQuiz),
    );
  }

  @override
  ConsumerState<CreateContestDialog> createState() => _CreateContestDialogState();
}

class _CreateContestDialogState extends ConsumerState<CreateContestDialog> {
  Quiz? _selectedQuiz;
  bool _requirePin = false;
  final TextEditingController _pinController = TextEditingController();
  int _maxParticipants = 20;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _selectedQuiz = widget.initialQuiz;
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _handleLaunch() async {
    if (_selectedQuiz == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a quiz to launch.'),
          backgroundColor: AppColors.gameRed,
        ),
      );
      return;
    }

    if (_requirePin && _pinController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a PIN or disable PIN requirement.'),
          backgroundColor: AppColors.gameRed,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    final contest = await ref
        .read(hostContestControllerProvider.notifier)
        .createAndLaunchContest(
          quiz: _selectedQuiz!,
          pin: _requirePin ? _pinController.text.trim() : null,
          maxParticipants: _maxParticipants,
        );

    if (mounted) {
      setState(() => _isCreating = false);
      if (contest != null) {
        Navigator.of(context).pop();
        context.push('/contests/host/${contest.id}');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to launch contest. Try again.'),
            backgroundColor: AppColors.gameRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userQuizzesAsync = ref.watch(userQuizzesProvider);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.90;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.sensors, color: AppColors.gameBlue, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Host Live Contest',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Select Quiz
                  Text(
                    'Select Quiz',
                    style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),

                  userQuizzesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('Error loading quizzes: $e'),
                    data: (quizzes) {
                      final publishedQuizzes = quizzes.where((q) => !q.isDraft).toList();

                      if (publishedQuizzes.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.amber.shade300),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'You don\'t have any published quizzes yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  context.push('/quizzes');
                                },
                                child: const Text('Open Quiz Studio'),
                              ),
                            ],
                          ),
                        );
                      }

                      _selectedQuiz ??= publishedQuizzes.first;

                      return DropdownButtonFormField<String>(
                        initialValue: _selectedQuiz?.id,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          filled: true,
                          fillColor: theme.colorScheme.surface,
                        ),
                        items: publishedQuizzes.map((q) {
                          return DropdownMenuItem<String>(
                            value: q.id,
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(q.themeColor),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${q.title} (${q.questionsCount} Qs)',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (quizId) {
                          setState(() {
                            _selectedQuiz = publishedQuizzes.firstWhere((q) => q.id == quizId);
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 2. Max Participants
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Max Participants',
                        style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_maxParticipants players',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  Slider(
                    value: _maxParticipants.toDouble(),
                    min: 2,
                    max: 50,
                    divisions: 24,
                    label: '$_maxParticipants',
                    onChanged: (val) => setState(() => _maxParticipants = val.round()),
                  ),
                  const SizedBox(height: 12),

                  // 3. Optional PIN
                  SwitchListTile(
                    title: const Text('Require PIN for Extra Security', style: TextStyle(fontSize: 14)),
                    subtitle: const Text('Only players who enter the PIN can join', style: TextStyle(fontSize: 12)),
                    value: _requirePin,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _requirePin = val),
                  ),

                  if (_requirePin) ...[
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _pinController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: InputDecoration(
                        labelText: 'Contest PIN',
                        hintText: 'e.g. 1234',
                        prefixIcon: const Icon(Icons.lock_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Launch Button
                  ElevatedButton.icon(
                    onPressed: _isCreating ? null : _handleLaunch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gameBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isCreating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.rocket_launch),
                    label: Text(
                      _isCreating ? 'Launching Lobby...' : 'Launch Live Lobby',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
