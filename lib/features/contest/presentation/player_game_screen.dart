import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quizapp/core/constants/app_colors.dart';
import 'package:quizapp/core/utils/image_utils.dart';
import 'package:quizapp/features/auth/presentation/auth_controller.dart';
import 'package:quizapp/features/quiz/domain/quiz_question.dart';
import 'package:quizapp/features/contest/data/firestore_contest_repository.dart';
import 'package:quizapp/features/contest/domain/contest.dart';
import 'package:quizapp/features/contest/presentation/controllers/player_game_controller.dart';
import 'package:quizapp/features/contest/presentation/widgets/answer_distribution_chart.dart';
import 'package:quizapp/features/contest/presentation/widgets/leaderboard_view.dart';
import 'package:quizapp/features/contest/presentation/widgets/podium_view.dart';

class PlayerGameScreen extends ConsumerStatefulWidget {
  final String contestId;

  const PlayerGameScreen({
    super.key,
    required this.contestId,
  });

  @override
  ConsumerState<PlayerGameScreen> createState() => _PlayerGameScreenState();
}

class _PlayerGameScreenState extends ConsumerState<PlayerGameScreen> {
  Timer? _countdownTimer;
  int _remainingSeconds = 0;
  int _lastHandledQuestionIndex = -2;
  final TextEditingController _textAnswerController = TextEditingController();
  List<int>? _orderingList;

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _textAnswerController.dispose();
    super.dispose();
  }

  void _syncTimer(Contest contest) {
    if (contest.stage != ContestStage.questionActive) {
      _countdownTimer?.cancel();
      return;
    }

    if (contest.currentQuestionIndex != _lastHandledQuestionIndex) {
      _lastHandledQuestionIndex = contest.currentQuestionIndex;
      _orderingList = null;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(playerGameControllerProvider.notifier).resetForNewQuestion();
          _textAnswerController.clear();
        }
      });

      final timeLimit = contest.activeQuestion?.timeLimitSeconds ?? 20;

      if (contest.questionOpenedAt != null) {
        final elapsed = DateTime.now().difference(contest.questionOpenedAt!).inSeconds;
        _remainingSeconds = (timeLimit - elapsed).clamp(0, timeLimit);
      } else {
        _remainingSeconds = timeLimit;
      }

      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        final currentContest = ref.read(contestStreamProvider(widget.contestId)).asData?.value;
        if (currentContest?.isPaused == true) return;

        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).asData?.value;
    final contestAsync = ref.watch(contestStreamProvider(widget.contestId));
    final participantsAsync = ref.watch(participantsStreamProvider(widget.contestId));
    final playerState = ref.watch(playerGameControllerProvider);
    final playerController = ref.read(playerGameControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          contestAsync.asData?.value?.quizTitle ?? 'Live Contest',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Leave Contest',
            onPressed: () => _confirmLeave(context),
          ),
        ],
      ),
      body: contestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading contest: $e')),
        data: (contest) {
          if (contest == null || (contest.status == ContestStatus.ended && contest.stage != ContestStage.podium)) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 56, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Contest has ended.', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            );
          }

          // Check if kicked
          if (user != null && contest.kickedUserIds.contains(user.id)) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You were removed from this contest by the host.'),
                    backgroundColor: AppColors.gameRed,
                  ),
                );
                context.go('/home');
              }
            });
            return const SizedBox.shrink();
          }

          // Sync timer
          _syncTimer(contest);

          final participants = participantsAsync.asData?.value ?? [];

          // Watch local player's answer submission for current question
          final answerAsync = user != null
              ? ref.watch(participantAnswerStreamProvider(
                  ParticipantAnswerQuery(
                    contestId: contest.id,
                    participantId: user.id,
                    questionIndex: contest.currentQuestionIndex,
                  ),
                ))
              : const AsyncValue.data(null);

          final myAnswer = answerAsync.asData?.value;
          final hasSubmitted = (playerState.hasSubmitted &&
                  playerState.submittedQuestionIndex == contest.currentQuestionIndex) ||
              myAnswer != null;

          switch (contest.stage) {
            case ContestStage.questionActive:
              return _buildQuestionActiveView(
                context: context,
                contest: contest,
                playerState: playerState,
                playerController: playerController,
                hasSubmitted: hasSubmitted,
              );

            case ContestStage.answerReveal:
              return _buildAnswerRevealView(
                context: context,
                contest: contest,
                myAnswer: myAnswer,
              );

            case ContestStage.leaderboard:
              return _buildLeaderboardView(
                context: context,
                contest: contest,
                participants: participants,
                currentUserId: user?.id,
              );

            case ContestStage.podium:
            case ContestStage.ended:
              return PodiumView(
                participants: participants,
                isHost: false,
                onFinish: () => context.go('/home'),
              );

            case ContestStage.lobby:
            case ContestStage.starting:
              return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  // 1. PARTICIPANT ACTIVE QUESTION VIEW
  Widget _buildQuestionActiveView({
    required BuildContext context,
    required Contest contest,
    required PlayerGameState playerState,
    required PlayerGameController playerController,
    required bool hasSubmitted,
  }) {
    final theme = Theme.of(context);
    final question = contest.activeQuestion;
    final timeLimit = question?.timeLimitSeconds ?? 20;
    final timerRatio = timeLimit > 0 ? (_remainingSeconds / timeLimit) : 0.0;

    final timerColor = _remainingSeconds <= 5
        ? AppColors.gameRed
        : (_remainingSeconds <= 10 ? AppColors.gameYellow : AppColors.accent);

    // If answer already submitted -> Show waiting state
    if (hasSubmitted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 54),
              ),
              const SizedBox(height: 24),
              const Text(
                'Answer Locked In!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for time to expire and other players to finish...',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                borderRadius: BorderRadius.circular(8),
                color: AppColors.accent,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
              ),
            ],
          ),
        ),
      );
    }

    // If time's up but not submitted -> Time's up state
    if (_remainingSeconds <= 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.timer_off_outlined, size: 64, color: AppColors.gameRed),
              const SizedBox(height: 16),
              const Text(
                "Time's Up!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.gameRed),
              ),
              const SizedBox(height: 8),
              Text(
                'Waiting for host to reveal the results...',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Column(
        children: [
          // Header info & Timer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Q${contest.currentQuestionIndex + 1} of ${contest.questionsCount}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, size: 18, color: timerColor),
                    const SizedBox(width: 4),
                    Text(
                      '$_remainingSeconds s',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: timerColor),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Linear timer bar
          LinearProgressIndicator(
            value: timerRatio,
            backgroundColor: Colors.grey.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(timerColor),
            minHeight: 4,
          ),

          // Question body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    question?.text ?? 'Question',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (question?.imageBase64 != null) ...[
                    Builder(
                      builder: (context) {
                        final imageBytes = ImageUtils.base64ToBytes(question!.imageBase64!);
                        if (imageBytes == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 160),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Option cards based on QuestionType
                  _buildInteractiveOptions(
                    context: context,
                    contest: contest,
                    question: question,
                    playerState: playerState,
                    playerController: playerController,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveOptions({
    required BuildContext context,
    required Contest contest,
    required ActiveQuestion? question,
    required PlayerGameState playerState,
    required PlayerGameController playerController,
  }) {
    if (question == null) return const SizedBox.shrink();

    const colors = [
      AppColors.gameRed,
      AppColors.gameBlue,
      AppColors.gameYellow,
      AppColors.gameGreen,
    ];

    const icons = [
      Icons.change_history,
      Icons.diamond_outlined,
      Icons.circle_outlined,
      Icons.crop_square,
    ];

    switch (question.type) {
      case QuestionType.multipleChoice:
      case QuestionType.trueFalse:
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.35,
          ),
          itemCount: question.options.length,
          itemBuilder: (context, index) {
            final color = colors[index % colors.length];
            final icon = icons[index % icons.length];
            final isSelected = playerState.selectedOptions.contains(index);

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: playerState.isSubmitting
                  ? null
                  : () async {
                      playerController.toggleOption(index, isMultiSelect: false);
                      await playerController.submitAnswer(
                        contestId: contest.id,
                        questionIndex: contest.currentQuestionIndex,
                      );
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      question.options[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );

      case QuestionType.multipleSelect:
        return Column(
          children: [
            ...List.generate(question.options.length, (index) {
              final color = colors[index % colors.length];
              final isSelected = playerState.selectedOptions.contains(index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => playerController.toggleOption(index, isMultiSelect: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? color : color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isSelected ? Colors.white : color,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: playerState.selectedOptions.isEmpty || playerState.isSubmitting
                    ? null
                    : () => playerController.submitAnswer(
                          contestId: contest.id,
                          questionIndex: contest.currentQuestionIndex,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gameGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Submit Answers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        );

      case QuestionType.shortText:
      case QuestionType.numeric:
        return Column(
          children: [
            TextFormField(
              controller: _textAnswerController,
              keyboardType: question.type == QuestionType.numeric
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                hintText: 'Type your answer here...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
              ),
              onChanged: (val) => playerController.setTextAnswer(val),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: playerState.selectedOptions.isEmpty || playerState.isSubmitting
                    ? null
                    : () => playerController.submitAnswer(
                          contestId: contest.id,
                          questionIndex: contest.currentQuestionIndex,
                        ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Submit Answer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        );

      case QuestionType.ordering:
        _orderingList ??= List.generate(question.options.length, (i) => i);
        return Column(
          children: [
            const Text('Drag items into correct order:', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _orderingList!.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _orderingList!.removeAt(oldIndex);
                  _orderingList!.insert(newIndex, item);
                  playerController.setOrdering(_orderingList!);
                });
              },
              itemBuilder: (context, index) {
                final optIdx = _orderingList![index];
                return Container(
                  key: ValueKey('order_$optIdx'),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors[index % colors.length].withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors[index % colors.length]),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.drag_handle, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          question.options[optIdx],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: playerState.isSubmitting
                    ? null
                    : () {
                        playerController.setOrdering(_orderingList!);
                        playerController.submitAnswer(
                          contestId: contest.id,
                          questionIndex: contest.currentQuestionIndex,
                        );
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.send),
                label: const Text('Submit Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        );
    }
  }

  // 2. ANSWER REVEAL (PLAYER VIEW)
  Widget _buildAnswerRevealView({
    required BuildContext context,
    required Contest contest,
    required dynamic myAnswer,
  }) {
    final question = contest.activeQuestion;
    final isCorrect = myAnswer?.isCorrect == true;
    final pointsAwarded = myAnswer?.pointsAwarded ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Correctness Hero Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isCorrect
                    ? [AppColors.gameGreen, const Color(0xFF00C897)]
                    : [AppColors.gameRed, const Color(0xFFFF5252)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isCorrect ? AppColors.gameGreen : AppColors.gameRed).withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 8),
                Text(
                  isCorrect ? 'CORRECT!' : 'INCORRECT',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isCorrect ? '+$pointsAwarded points' : '+0 points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Distribution chart
          if (question != null)
            AnswerDistributionChart(
              options: question.options,
              correctAnswers: question.correctAnswers,
              distribution: contest.answerDistribution,
            ),

          if (question?.explanation != null && question!.explanation!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Text(
                'Explanation: ${question.explanation!}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 3. LEADERBOARD (PLAYER VIEW)
  Widget _buildLeaderboardView({
    required BuildContext context,
    required Contest contest,
    required List<dynamic> participants,
    required String? currentUserId,
  }) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
              const SizedBox(width: 8),
              Text(
                'Round ${contest.currentQuestionIndex + 1} Standings',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LeaderboardView(
            participants: participants.cast(),
            currentUserId: currentUserId,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Contest?'),
        content: const Text('Are you sure you want to exit the contest?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Stay')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gameRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Leave', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.go('/home');
    }
  }
}
