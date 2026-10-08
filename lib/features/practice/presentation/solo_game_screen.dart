import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/game_animations.dart';
import '../../../core/services/sound_service.dart';
import '../../quiz/data/firestore_quiz_repository.dart';

import '../../quiz/domain/quiz.dart';
import '../../quiz/domain/quiz_question.dart';
import '../data/sample_quizzes.dart';
import 'solo_game_controller.dart';
import 'solo_results_screen.dart';

final soloQuizLoaderProvider =
    FutureProvider.family<Quiz?, String>((ref, quizId) async {
  final sample = SampleQuizzes.getById(quizId);
  if (sample != null) return sample;
  return ref.watch(quizRepositoryProvider).getQuiz(quizId);
});

class SoloGameScreen extends ConsumerStatefulWidget {
  final String quizId;

  const SoloGameScreen({super.key, required this.quizId});

  @override
  ConsumerState<SoloGameScreen> createState() => _SoloGameScreenState();
}

class _SoloGameScreenState extends ConsumerState<SoloGameScreen> {
  final TextEditingController _textInputController = TextEditingController();
  List<int>? _localOrderingList;

  @override
  void dispose() {
    _textInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(soloQuizLoaderProvider(widget.quizId));
    final gameState = ref.watch(soloGameControllerProvider);
    final gameController = ref.read(soloGameControllerProvider.notifier);

    return quizAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Scaffold(
        appBar: AppBar(title: const Text('Solo Practice')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 56, color: AppColors.gameRed),
                const SizedBox(height: 16),
                Text('Could not load quiz: $err', textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to Quizzes'),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (quiz) {
        if (quiz == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Solo Practice')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Quiz not found.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text('Back to Quizzes'),
                  ),
                ],
              ),
            ),
          );
        }

        // Initialize session if not loaded yet or if playing a different quiz
        if (gameState.quiz?.id != quiz.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            gameController.initGame(quiz);
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Finished quiz -> show results screen
        if (gameState.isFinished) {
          return const SoloResultsScreen();
        }

        final question = gameState.currentQuestion;
        if (question == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return _buildActiveGameScaffold(
          context: context,
          quiz: quiz,
          question: question,
          state: gameState,
          controller: gameController,
        );
      },
    );
  }

  Widget _buildActiveGameScaffold({
    required BuildContext context,
    required Quiz quiz,
    required QuizQuestion question,
    required SoloGameState state,
    required SoloGameController controller,
  }) {
    final theme = Theme.of(context);
    final isRevealed = state.isAnswerRevealed;

    // Reset local controllers when question index changes
    if (!isRevealed && _textInputController.text != state.textAnswer) {
      _textInputController.text = state.textAnswer;
    }

    final timerRatio = state.totalQuestionSeconds > 0
        ? state.remainingSeconds / state.totalQuestionSeconds
        : 0.0;

    final timerColor = timerRatio > 0.45
        ? AppColors.gameGreen
        : timerRatio > 0.2
            ? AppColors.gameYellow
            : AppColors.gameRed;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmExit(context);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => _confirmExit(context),
          ),
          title: Text(
            'Q${state.currentQuestionIndex + 1} of ${state.totalQuestions}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          centerTitle: true,
          actions: [
            // Animated Streak Flame
            if (state.streak > 0) ...[
              AnimatedStreakFlame(streak: state.streak),
              const SizedBox(width: 8),
            ],

            // Score Pill
            Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${state.score}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(6),
            child: LinearProgressIndicator(
              value: state.progressRatio,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ),
        body: Column(
          children: [
            // Timer Bar (active only when answering with urgency pulse)
            if (!isRevealed)
              UrgencyPulse(
                isUrgent: state.remainingSeconds <= 5,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.colorScheme.surface,
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 18, color: timerColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: timerRatio,
                            minHeight: 10,
                            backgroundColor: Colors.grey.withValues(alpha: 0.2),
                            valueColor: AlwaysStoppedAnimation(timerColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${state.remainingSeconds}s',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: timerColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Main Content Area

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question Type & Points Tag
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            question.type.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${question.basePoints} pts',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Question Text Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        question.text,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Question Images (if available)
                    if (question.imagesBase64.isNotEmpty) ...[
                      _buildImagePreview(question.imagesBase64.first),
                      const SizedBox(height: 14),
                    ],

                    // Dynamic Answering or Result Section
                    if (!isRevealed)
                      _buildInteractiveInput(
                        context: context,
                        question: question,
                        state: state,
                        controller: controller,
                      )
                    else
                      _buildAnswerFeedback(
                        context: context,
                        question: question,
                        state: state,
                        controller: controller,
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Action for Answer Revealed State
            if (isRevealed)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _localOrderingList = null;
                      controller.nextQuestion();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.isLastQuestion
                              ? 'View Final Results'
                              : 'Next Question',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          state.isLastQuestion
                              ? Icons.emoji_events_rounded
                              : Icons.arrow_forward_rounded,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(String base64Str) {
    try {
      final bytes = base64Decode(
        base64Str.startsWith('data:') ? base64Str.split(',').last : base64Str,
      );
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 220),
          width: double.infinity,
          color: Colors.black12,
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  // 1. INPUT WIDGETS
  Widget _buildInteractiveInput({
    required BuildContext context,
    required QuizQuestion question,
    required SoloGameState state,
    required SoloGameController controller,
  }) {
    const colors = [
      AppColors.gameRed,
      AppColors.gameBlue,
      AppColors.gameYellow,
      AppColors.gameGreen,
    ];
    const icons = [
      Icons.change_history,
      Icons.square_outlined,
      Icons.circle_outlined,
      Icons.star_border,
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
            final isSelected = state.selectedAnswers.contains(index);

            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                ref.read(soundServiceProvider).playClick();
                controller.toggleOption(index, isMultiSelect: false);
                controller.submitAnswer();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: Colors.white, width: 3)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
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
              final isSelected = state.selectedAnswers.contains(index);

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    ref.read(soundServiceProvider).playClick();
                    controller.toggleOption(index, isMultiSelect: true);
                  },
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
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
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
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.selectedAnswers.isEmpty
                    ? null
                    : () {
                        ref.read(soundServiceProvider).playClick();
                        controller.submitAnswer();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gameGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Submit Answers',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        );

      case QuestionType.shortText:
      case QuestionType.numeric:
        return Column(
          children: [
            TextField(
              controller: _textInputController,
              keyboardType: question.type == QuestionType.numeric
                  ? TextInputType.number
                  : TextInputType.text,
              autofocus: true,
              decoration: InputDecoration(
                hintText: question.type == QuestionType.numeric
                    ? 'Enter number (e.g., 42)...'
                    : 'Type answer...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                filled: true,
              ),
              onChanged: (val) => controller.setTextAnswer(val),
              onSubmitted: (_) {
                if (_textInputController.text.trim().isNotEmpty) {
                  ref.read(soundServiceProvider).playClick();
                  controller.submitAnswer();
                }
              },
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: state.textAnswer.trim().isEmpty
                    ? null
                    : () {
                        ref.read(soundServiceProvider).playClick();
                        controller.submitAnswer();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Submit Answer',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        );

      case QuestionType.ordering:
        _localOrderingList ??=
            state.orderingList ?? List.generate(question.options.length, (i) => i);

        return Column(
          children: [
            const Text(
              'Drag items into the correct order:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _localOrderingList!.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                ref.read(soundServiceProvider).playClick();
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _localOrderingList!.removeAt(oldIndex);
                  _localOrderingList!.insert(newIndex, item);
                  controller.setOrdering(_localOrderingList!);
                });
              },
              itemBuilder: (context, index) {
                final optIdx = _localOrderingList![index];
                return Container(
                  key: ValueKey('order_opt_$optIdx'),
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
                onPressed: () {
                  controller.setOrdering(_localOrderingList!);
                  controller.submitAnswer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.send_rounded),
                label: const Text(
                  'Submit Order',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        );
    }
  }

  // 2. ANSWER FEEDBACK & EXPLANATIONS
  Widget _buildAnswerFeedback({
    required BuildContext context,
    required QuizQuestion question,
    required SoloGameState state,
    required SoloGameController controller,
  }) {
    final lastAns = state.lastAnswer;
    final isCorrect = lastAns?.isCorrect == true;
    final pointsAwarded = lastAns?.pointsAwarded ?? 0;
    final streak = lastAns?.streak ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Result Hero Banner with PopIn bounce
        PopIn(
          child: Container(
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
                  color: (isCorrect ? AppColors.gameGreen : AppColors.gameRed)
                      .withValues(alpha: 0.35),
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
                size: 46,
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
              if (isCorrect && streak > 1) ...[
                const SizedBox(height: 6),
                Text(
                  '🔥 Streak x$streak bonus!',
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      const SizedBox(height: 16),


        // Correct Answer Reference Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.gameGreen, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Correct Answer:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                lastAns?.formattedCorrectAnswer ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gameGreen,
                ),
              ),
              if (!isCorrect) ...[
                const SizedBox(height: 10),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your answer: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: Text(
                        lastAns?.formattedUserAnswer ?? 'None',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.gameRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        // Explanation (if present)
        if (question.explanation != null &&
            question.explanation!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Explanation',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.explanation!,
                        style: const TextStyle(fontSize: 13, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _confirmExit(BuildContext context) async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Practice Session?'),
        content: const Text(
          'Are you sure you want to exit? Your current progress and score will not be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Playing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.gameRed),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLeave == true && context.mounted) {
      context.pop();
    }
  }
}
