import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../domain/quiz_question.dart';
import 'quiz_editor_controller.dart';
import 'widgets/question_card.dart';
import 'widgets/question_editor_dialog.dart';

class QuizEditorScreen extends ConsumerStatefulWidget {
  final String? quizId;

  const QuizEditorScreen({
    super.key,
    this.quizId,
  });

  @override
  ConsumerState<QuizEditorScreen> createState() => _QuizEditorScreenState();
}

class _QuizEditorScreenState extends ConsumerState<QuizEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  bool _initializedControllers = false;

  static const List<int> _themeColors = [
    0xFF6C4AB6, // Royal Violet
    0xFFE21B3C, // Crimson
    0xFF1368CE, // Blue
    0xFF26890C, // Green
    0xFFFFA602, // Amber Orange
    0xFF00C897, // Mint Emerald
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _syncControllersWithQuiz(String title, String desc) {
    if (!_initializedControllers && title.isNotEmpty) {
      _titleController.text = title;
      _descController.text = desc;
      _initializedControllers = true;
    }
  }

  Future<bool> _onWillPop(QuizEditorState state) async {
    if (!state.hasUnsavedChanges) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved changes in this quiz. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep Editing'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.gameRed),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  void _openAddQuestionDialog() {
    QuestionEditorDialog.show(
      context: context,
      question: QuizQuestion.empty(),
      questionNumber: ref.read(quizEditorControllerProvider(widget.quizId)).quiz.questions.length + 1,
      onSave: (newQuestion) {
        ref.read(quizEditorControllerProvider(widget.quizId).notifier).addQuestion(newQuestion);
      },
    );
  }

  void _openEditQuestionDialog(int index, QuizQuestion question) {
    QuestionEditorDialog.show(
      context: context,
      question: question,
      questionNumber: index + 1,
      onSave: (updatedQuestion) {
        ref.read(quizEditorControllerProvider(widget.quizId).notifier).updateQuestion(index, updatedQuestion);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizEditorControllerProvider(widget.quizId));
    final controller = ref.read(quizEditorControllerProvider(widget.quizId).notifier);
    final quiz = state.quiz;
    final theme = Theme.of(context);

    // Sync controllers once quiz data arrives (when editing existing quiz)
    _syncControllersWithQuiz(quiz.title, quiz.description);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Size quota calculation
    final sizeBytes = quiz.estimatedSizeBytes;
    final sizeKb = sizeBytes / 1024;
    final maxDocKb = AppConstants.maxDocSizeBytes / 1024;
    final sizeRatio = (sizeBytes / AppConstants.maxDocSizeBytes).clamp(0.0, 1.0);
    final isSizeWarning = sizeRatio > 0.75;
    final isSizeDanger = sizeRatio > 0.90;

    final sizeColor = isSizeDanger
        ? AppColors.gameRed
        : (isSizeWarning ? Colors.orange : AppColors.accent);

    return PopScope(
      canPop: !state.hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop(state);
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.quizId == null ? 'Create Quiz' : 'Edit Quiz',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          actions: [
            // Save as Draft button
            TextButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () async {
                      final success = await controller.saveDraft();
                      if (success && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Draft saved successfully!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        context.pop();
                      }
                    },
              icon: const Icon(Icons.bookmark_border, size: 18),
              label: const Text('Draft'),
            ),

            // Publish button
            Padding(
              padding: const EdgeInsets.only(right: 12, left: 4),
              child: ElevatedButton.icon(
                onPressed: state.isSaving
                    ? null
                    : () async {
                        final success = await controller.publish();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Quiz published! Ready to host.'),
                              backgroundColor: AppColors.accent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          context.pop();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
                icon: state.isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check, size: 16),
                label: const Text('Publish'),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Document Size Quota Meter (Firestore 1 MB ceiling enforcement)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storage_outlined, size: 14, color: sizeColor),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Firestore Quota',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${sizeKb.toStringAsFixed(1)} KB / ${maxDocKb.toStringAsFixed(0)} KB (${(sizeRatio * 100).toStringAsFixed(1)}%)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: sizeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: sizeRatio,
                      minHeight: 5,
                      backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(sizeColor),
                    ),
                  ),
                ],
              ),
            ),

            // Error Banner if validation fails
            if (state.errorMessage != null)
              Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.gameRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.gameRed.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.gameRed, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage!,
                        style: const TextStyle(
                          color: AppColors.gameRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quiz Details Card
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quiz Details',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Title Input
                              TextFormField(
                                controller: _titleController,
                                decoration: const InputDecoration(
                                  labelText: 'Quiz Title *',
                                  hintText: 'e.g. Cosmic Trivia Challenge',
                                  prefixIcon: Icon(Icons.title),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                                onChanged: (val) => controller.updateTitle(val),
                              ),
                              const SizedBox(height: 14),

                              // Description Input
                              TextFormField(
                                controller: _descController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Description (Optional)',
                                  hintText: 'A fun quiz to test space knowledge with friends...',
                                  prefixIcon: Icon(Icons.description_outlined),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(Radius.circular(12)),
                                  ),
                                ),
                                onChanged: (val) => controller.updateDescription(val),
                              ),
                              const SizedBox(height: 14),

                              // Theme Color Swatches
                              const Text(
                                'Theme Color',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 8,
                                children: _themeColors.map((colorVal) {
                                  final isSelected = quiz.themeColor == colorVal;
                                  return GestureDetector(
                                    onTap: () => controller.updateThemeColor(colorVal),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: Color(colorVal),
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(color: Colors.white, width: 3)
                                            : null,
                                        boxShadow: isSelected
                                            ? [
                                                BoxShadow(
                                                  color: Color(colorVal).withValues(alpha: 0.6),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: isSelected
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 18)
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Questions Section Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'Questions (${quiz.questionsCount})',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (quiz.questionsCount > 0)
                                  Text(
                                    '• ~${quiz.totalTimeSeconds}s • ${quiz.totalPoints} pts',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: _openAddQuestionDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Question'),
                          ),
                        ],
                      ),
                    ),

                    // Questions List or Empty State
                    if (quiz.questions.isEmpty)
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.quiz_outlined,
                              size: 48,
                              color: theme.colorScheme.primary.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No questions yet',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Add your first multiple-choice question with timers, points, and compressed images.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _openAddQuestionDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add First Question'),
                            ),
                          ],
                        ),
                      )
                    else
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: quiz.questions.length,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          controller.reorderQuestions(oldIndex, newIndex);
                        },
                        itemBuilder: (context, idx) {
                          final q = quiz.questions[idx];
                          return QuestionCard(
                            key: ValueKey(q.id),
                            index: idx,
                            totalCount: quiz.questions.length,
                            question: q,
                            onEdit: () => _openEditQuestionDialog(idx, q),
                            onDuplicate: () => controller.duplicateQuestion(idx),
                            onDelete: () => controller.removeQuestion(idx),
                            onMoveUp: idx > 0 ? () => controller.moveQuestionUp(idx) : null,
                            onMoveDown: idx < quiz.questions.length - 1
                                ? () => controller.moveQuestionDown(idx)
                                : null,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddQuestionDialog,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Add Question'),
        ),
      ),
    );
  }
}
