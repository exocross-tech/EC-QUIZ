import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/utils/image_utils.dart';
import '../../domain/quiz_question.dart';

class QuestionEditorDialog extends StatefulWidget {
  final QuizQuestion question;
  final int questionNumber;
  final ValueChanged<QuizQuestion> onSave;

  const QuestionEditorDialog({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required QuizQuestion question,
    required int questionNumber,
    required ValueChanged<QuizQuestion> onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => QuestionEditorDialog(
        question: question,
        questionNumber: questionNumber,
        onSave: onSave,
      ),
    );
  }

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> {
  late TextEditingController _textController;
  late TextEditingController _explanationController;
  late List<TextEditingController> _optionControllers;
  late List<int> _correctAnswers;
  late int _timeLimitSeconds;
  late int _basePoints;
  late List<String> _imagesBase64;
  bool _isCompressingImage = false;
  String? _imageError;

  static const List<int> _availableTimes = [5, 10, 20, 30, 60, 90, 120];
  static const List<int> _availablePoints = [500, 1000, 2000];

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
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.question.text);
    _explanationController =
        TextEditingController(text: widget.question.explanation ?? '');
    _timeLimitSeconds = widget.question.timeLimitSeconds;
    _basePoints = widget.question.basePoints;
    _imagesBase64 = List<String>.from(widget.question.imagesBase64);
    _correctAnswers = List.from(widget.question.correctAnswers);

    final initialOpts = widget.question.options.isEmpty
        ? ['', '', '', '']
        : widget.question.options;
    _optionControllers =
        initialOpts.map((opt) => TextEditingController(text: opt)).toList();
  }

  @override
  void dispose() {
    _textController.dispose();
    _explanationController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndCompressImage(ImageSource source) async {
    if (_imagesBase64.length >= 4) {
      setState(() {
        _imageError = 'Maximum of 4 images allowed per question.';
      });
      return;
    }

    setState(() {
      _isCompressingImage = true;
      _imageError = null;
    });

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked == null) {
        setState(() => _isCompressingImage = false);
        return;
      }

      final rawBytes = await picked.readAsBytes();
      final base64String = await ImageUtils.compressAndEncodeBase64(
        rawBytes,
        maxSizeBytes: AppConstants.maxImageSizeBytes,
      );

      setState(() {
        _imagesBase64.add(base64String);
        _isCompressingImage = false;
      });
    } catch (e) {
      setState(() {
        _isCompressingImage = false;
        _imageError = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index >= 0 && index < _imagesBase64.length) {
        _imagesBase64.removeAt(index);
      }
    });
  }

  void _addOption() {
    if (_optionControllers.length >= 6) return;
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(index);
      _correctAnswers.remove(index);
      // Shift indices higher than index down by 1
      _correctAnswers = _correctAnswers.map((a) => a > index ? a - 1 : a).toList();
      if (_correctAnswers.isEmpty && _optionControllers.isNotEmpty) {
        _correctAnswers.add(0);
      }
    });
  }

  void _toggleCorrectAnswer(int index) {
    setState(() {
      if (_correctAnswers.contains(index)) {
        if (_correctAnswers.length > 1) {
          _correctAnswers.remove(index);
        }
      } else {
        _correctAnswers.add(index);
      }
    });
  }

  void _handleSave() {
    final text = _textController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).toList();
    final explanation = _explanationController.text.trim();

    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter question text.'),
          backgroundColor: AppColors.gameRed,
        ),
      );
      return;
    }

    if (options.length < 2 || options.any((o) => o.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all option answers (at least 2).'),
          backgroundColor: AppColors.gameRed,
        ),
      );
      return;
    }

    if (_correctAnswers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one correct answer.'),
          backgroundColor: AppColors.gameRed,
        ),
      );
      return;
    }

    final updated = widget.question.copyWith(
      text: text,
      options: options,
      correctAnswers: _correctAnswers,
      timeLimitSeconds: _timeLimitSeconds,
      basePoints: _basePoints,
      explanation: explanation.isNotEmpty ? explanation : null,
      imagesBase64: _imagesBase64,
      clearImage: _imagesBase64.isEmpty,
    );

    widget.onSave(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.92;

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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    'Q${widget.questionNumber}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Edit Question ${widget.questionNumber}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Scrollable Editor Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Question Text
                  Text(
                    'Question Text',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _textController,
                    maxLines: 3,
                    minLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Which planet has the most moons?',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Question Images (Compressed base64 in Firestore, max 4)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Question Images (Optional, max 4)',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_imagesBase64.isNotEmpty)
                        Text(
                          '${_imagesBase64.length}/4',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_imagesBase64.isNotEmpty) ...[
                    SizedBox(
                      height: 104,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imagesBase64.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final bytes = ImageUtils.base64ToBytes(_imagesBase64[index]);
                          final sizeKb = bytes != null
                              ? (bytes.lengthInBytes / 1024).toStringAsFixed(1)
                              : '0';
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 90,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(11),
                                        ),
                                        child: bytes != null
                                            ? Image.memory(
                                                bytes,
                                                width: double.infinity,
                                                fit: BoxFit.cover,
                                                gaplessPlayback: true,
                                              )
                                            : const Icon(Icons.broken_image, size: 28),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 3,
                                        horizontal: 4,
                                      ),
                                      child: Text(
                                        '$sizeKb KB',
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                top: -6,
                                right: -6,
                                child: InkWell(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.gameRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],

                  if (_isCompressingImage)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Compressing image under 200 KB...',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else if (_imagesBase64.length < 4)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _pickAndCompressImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt, size: 18),
                            label: Text(
                              _imagesBase64.isEmpty ? 'Camera' : 'Add Image',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _pickAndCompressImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: Text(
                              _imagesBase64.isEmpty ? 'Gallery' : 'Add Image',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),

                  if (_imageError != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _imageError!,
                      style: const TextStyle(
                        color: AppColors.gameRed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),

                  // 3. Time Limit Selector
                  Text(
                    'Time Limit',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _availableTimes.map((secs) {
                        final isSelected = _timeLimitSeconds == secs;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('${secs}s'),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _timeLimitSeconds = secs);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Points Selector
                  Text(
                    'Points Value',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availablePoints.map((pts) {
                      final isSelected = _basePoints == pts;
                      return ChoiceChip(
                        label: Text('$pts pts'),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _basePoints = pts);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 22),

                  // 5. Answer Options with Kahoot styling
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Answers (Tap circle to mark correct)',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_optionControllers.length < 6)
                        TextButton.icon(
                          onPressed: _addOption,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Option', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Options list
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _optionControllers.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, optIdx) {
                      final isCorrect = _correctAnswers.contains(optIdx);
                      final optColor = _optionColors[optIdx % _optionColors.length];
                      final symbol = _optionSymbols[optIdx % _optionSymbols.length];

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCorrect
                              ? optColor.withValues(alpha: 0.12)
                              : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isCorrect
                                ? optColor
                                : theme.colorScheme.outlineVariant,
                            width: isCorrect ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            // Symbol Icon badge
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: optColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  symbol,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Option text input
                            Expanded(
                              child: TextFormField(
                                controller: _optionControllers[optIdx],
                                decoration: InputDecoration(
                                  hintText: 'Answer option ${optIdx + 1}',
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),

                            // Correct Answer toggle button
                            IconButton(
                              tooltip: isCorrect ? 'Correct Answer' : 'Mark as Correct',
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.all(4),
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                isCorrect
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: isCorrect
                                    ? optColor
                                    : Colors.grey,
                                size: 24,
                              ),
                              onPressed: () => _toggleCorrectAnswer(optIdx),
                            ),

                            // Delete option button (if > 2)
                            if (_optionControllers.length > 2) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
                                tooltip: 'Remove Option',
                                onPressed: () => _removeOption(optIdx),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 6. Optional Explanation
                  Text(
                    'Explanation (Optional, shown after answer reveal)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _explanationController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. Saturn currently has 146 confirmed moons.',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: theme.colorScheme.surface,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Question Button
                  ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Save Question',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
