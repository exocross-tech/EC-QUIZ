import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/image_utils.dart';
import '../../domain/quiz_question.dart';

class QuestionCard extends StatelessWidget {
  final int index;
  final int totalCount;
  final QuizQuestion question;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  const QuestionCard({
    super.key,
    required this.index,
    required this.totalCount,
    required this.question,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
    this.onMoveUp,
    this.onMoveDown,
  });

  static const List<Color> _optionColors = [
    AppColors.gameRed,
    AppColors.gameBlue,
    AppColors.gameYellow,
    AppColors.gameGreen,
    Color(0xFF8E24AA),
    Color(0xFF00897B),
  ];

  static const List<String> _optionSymbols = [
    '▲',
    '◆',
    '●',
    '■',
    '★',
    '✦',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = question.imagesBase64.isNotEmpty;
    final imageBytes = hasImage ? ImageUtils.base64ToBytes(question.imagesBase64.first) : null;
    final imageCount = question.imagesBase64.length;
    final isValid = question.isValidForPublish;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isValid
              ? theme.colorScheme.outlineVariant.withValues(alpha: 0.4)
              : Colors.amber.shade700,
          width: isValid ? 1 : 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Question number, Reorder buttons, Action menu
            Row(
              children: [
                // Question index badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Q${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Question type badge
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
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),

                const Spacer(),

                // Mobile move up/down buttons
                if (onMoveUp != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Move up',
                    onPressed: index > 0 ? onMoveUp : null,
                  ),
                if (onMoveDown != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Move down',
                    onPressed: index < totalCount - 1 ? onMoveDown : null,
                  ),

                // More menu: Duplicate, Delete
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  tooltip: 'Actions',
                  onSelected: (val) {
                    if (val == 'edit') onEdit();
                    if (val == 'duplicate') onDuplicate();
                    if (val == 'delete') onDelete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18),
                          SizedBox(width: 8),
                          Text('Edit Question'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: AppColors.gameRed, size: 18),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: AppColors.gameRed)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Middle: Text & optional image thumbnail
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.text.isEmpty
                            ? '(No question text entered yet)'
                            : question.text,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          fontStyle: question.text.isEmpty
                              ? FontStyle.italic
                              : FontStyle.normal,
                          color: question.text.isEmpty
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (question.explanation != null &&
                          question.explanation!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          '💡 ${question.explanation}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (imageBytes != null) ...[
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Image.memory(
                          imageBytes,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          gaplessPlayback: true,
                        ),
                        if (imageCount > 1)
                          Positioned(
                            top: 2,
                            left: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.75),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.photo_library, size: 9, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    '$imageCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${(imageBytes.lengthInBytes / 1024).toStringAsFixed(0)}KB',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Answer options preview grid / wrap
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: List.generate(question.options.length, (optIdx) {
                final isCorrect = question.correctAnswers.contains(optIdx);
                final optColor = _optionColors[optIdx % _optionColors.length];
                final symbol = _optionSymbols[optIdx % _optionSymbols.length];
                final optText = question.options[optIdx];

                return Container(
                  constraints: const BoxConstraints(maxWidth: 160),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? optColor.withValues(alpha: 0.15)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: isCorrect
                        ? Border.all(color: optColor, width: 1.5)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: optColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          symbol,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          optText.isEmpty ? '(Empty)' : optText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                            color: isCorrect
                                ? optColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      if (isCorrect) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle, size: 14, color: optColor),
                      ],
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 12),

            // Bottom Badges: Timer & Points & Edit Button
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildBadge(
                      Icons.timer_outlined,
                      '${question.timeLimitSeconds}s',
                      Colors.blue.shade700,
                      theme,
                    ),
                    const SizedBox(width: 8),
                    _buildBadge(
                      Icons.star_outline,
                      '${question.basePoints} pts',
                      Colors.amber.shade800,
                      theme,
                    ),
                    if (!isValid) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Needs completion',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                TextButton.icon(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  ),
                  icon: const Icon(Icons.edit, size: 15),
                  label: const Text('Edit', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(IconData icon, String text, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
