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
  late QuestionType _selectedType;
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
    _selectedType = widget.question.type;
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

  void _onTypeChanged(QuestionType newType) {
    if (_selectedType == newType) return;
    setState(() {
      _selectedType = newType;
      switch (newType) {
        case QuestionType.multipleChoice:
          if (_optionControllers.length < 2) {
            while (_optionControllers.length < 4) {
              _optionControllers.add(TextEditingController());
            }
          }
          if (_correctAnswers.isEmpty || _correctAnswers.first >= _optionControllers.length) {
            _correctAnswers = [0];
          } else {
            _correctAnswers = [_correctAnswers.first];
          }
          break;

        case QuestionType.trueFalse:
          for (final c in _optionControllers) {
            c.dispose();
          }
          _optionControllers = [
            TextEditingController(text: 'True'),
            TextEditingController(text: 'False'),
          ];
          _correctAnswers = [0];
          break;

        case QuestionType.multipleSelect:
          if (_optionControllers.length < 2) {
            while (_optionControllers.length < 4) {
              _optionControllers.add(TextEditingController());
            }
          }
          if (_correctAnswers.isEmpty) {
            _correctAnswers = [0, 1];
          }
          break;

        case QuestionType.shortText:
          for (final c in _optionControllers) {
            c.dispose();
          }
          _optionControllers = [
            TextEditingController(),
          ];
          _correctAnswers = [0];
          break;

        case QuestionType.numeric:
          for (final c in _optionControllers) {
            c.dispose();
          }
          _optionControllers = [
            TextEditingController(),
          ];
          _correctAnswers = [0];
          break;

        case QuestionType.ordering:
          if (_optionControllers.length < 3) {
            while (_optionControllers.length < 4) {
              _optionControllers.add(TextEditingController());
            }
          }
          _correctAnswers = List.generate(_optionControllers.length, (i) => i);
          break;
      }
    });
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
      if (_selectedType == QuestionType.ordering) {
        _correctAnswers = List.generate(_optionControllers.length, (i) => i);
      }
    });
  }

  void _removeOption(int index) {
    final minLimit = _selectedType == QuestionType.ordering ? 3 : 2;
    if (_optionControllers.length <= minLimit) return;
    setState(() {
      final removed = _optionControllers.removeAt(index);
      removed.dispose();
      if (_selectedType == QuestionType.ordering) {
        _correctAnswers = List.generate(_optionControllers.length, (i) => i);
      } else {
        _correctAnswers.remove(index);
        _correctAnswers = _correctAnswers.map((a) => a > index ? a - 1 : a).toList();
        if (_correctAnswers.isEmpty && _optionControllers.isNotEmpty) {
          _correctAnswers.add(0);
        }
      }
    });
  }

  void _setSingleCorrectAnswer(int index) {
    setState(() {
      _correctAnswers = [index];
    });
  }

  void _toggleMultiCorrectAnswer(int index) {
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

  void _moveOrderingItem(int oldIndex, int newIndex) {
    if (newIndex < 0 || newIndex >= _optionControllers.length) return;
    setState(() {
      final item = _optionControllers.removeAt(oldIndex);
      _optionControllers.insert(newIndex, item);
      _correctAnswers = List.generate(_optionControllers.length, (i) => i);
    });
  }

  static IconData _getTypeIcon(QuestionType type) {
    switch (type) {
      case QuestionType.multipleChoice:
        return Icons.radio_button_checked;
      case QuestionType.trueFalse:
        return Icons.thumbs_up_down_outlined;
      case QuestionType.multipleSelect:
        return Icons.check_box_outlined;
      case QuestionType.shortText:
        return Icons.text_fields;
      case QuestionType.numeric:
        return Icons.numbers;
      case QuestionType.ordering:
        return Icons.format_list_numbered;
    }
  }

  void _handleSave() {
    final text = _textController.text.trim();
    final options = _optionControllers.map((c) => c.text.trim()).toList();
    final explanation = _explanationController.text.trim();

    List<int> correctAnswers = List.from(_correctAnswers);
    if (_selectedType == QuestionType.ordering) {
      correctAnswers = List.generate(options.length, (i) => i);
    } else if (_selectedType == QuestionType.shortText || _selectedType == QuestionType.numeric) {
      correctAnswers = [0];
    }

    final updated = widget.question.copyWith(
      text: text,
      type: _selectedType,
      options: options,
      correctAnswers: correctAnswers,
      timeLimitSeconds: _timeLimitSeconds,
      basePoints: _basePoints,
      explanation: explanation.isNotEmpty ? explanation : null,
      imagesBase64: _imagesBase64,
      clearImage: _imagesBase64.isEmpty,
    );

    final error = updated.validationError;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.gameRed,
        ),
      );
      return;
    }

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
                  // Question Type Selector
                  Text(
                    'Question Type',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: QuestionType.values.map((type) {
                        final isSelected = _selectedType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            avatar: Icon(
                              _getTypeIcon(type),
                              size: 16,
                              color: isSelected ? Colors.white : theme.colorScheme.primary,
                            ),
                            label: Text(type.label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                _onTypeChanged(type);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),

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
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
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

                  // 5. Dynamic Answer Options
                  _buildAnswerOptionsSection(theme),
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

  Widget _buildAnswerOptionsSection(ThemeData theme) {
    switch (_selectedType) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceEditor(theme);
      case QuestionType.trueFalse:
        return _buildTrueFalseEditor(theme);
      case QuestionType.multipleSelect:
        return _buildMultipleSelectEditor(theme);
      case QuestionType.shortText:
        return _buildShortTextEditor(theme);
      case QuestionType.numeric:
        return _buildNumericEditor(theme);
      case QuestionType.ordering:
        return _buildOrderingEditor(theme);
    }
  }

  // 1. Multiple Choice Editor
  Widget _buildMultipleChoiceEditor(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Options (Tap circle to mark single correct)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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
                color: isCorrect ? optColor.withValues(alpha: 0.12) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCorrect ? optColor : theme.colorScheme.outlineVariant,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
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
                  IconButton(
                    tooltip: isCorrect ? 'Correct Answer' : 'Mark as Correct',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isCorrect ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: isCorrect ? optColor : Colors.grey,
                      size: 24,
                    ),
                    onPressed: () => _setSingleCorrectAnswer(optIdx),
                  ),
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
      ],
    );
  }

  // 2. True / False Editor
  Widget _buildTrueFalseEditor(ThemeData theme) {
    final isTrueCorrect = _correctAnswers.contains(0);
    final isFalseCorrect = _correctAnswers.contains(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Select the Correct Statement',
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _setSingleCorrectAnswer(0),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isTrueCorrect
                        ? AppColors.gameGreen.withValues(alpha: 0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isTrueCorrect ? AppColors.gameGreen : theme.colorScheme.outlineVariant,
                      width: isTrueCorrect ? 2.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isTrueCorrect ? Icons.check_circle : Icons.circle_outlined,
                        color: isTrueCorrect ? AppColors.gameGreen : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TRUE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gameGreen,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _setSingleCorrectAnswer(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isFalseCorrect
                        ? AppColors.gameRed.withValues(alpha: 0.15)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isFalseCorrect ? AppColors.gameRed : theme.colorScheme.outlineVariant,
                      width: isFalseCorrect ? 2.5 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isFalseCorrect ? Icons.cancel : Icons.circle_outlined,
                        color: isFalseCorrect ? AppColors.gameRed : Colors.grey,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'FALSE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.gameRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Multiple Select Editor
  Widget _buildMultipleSelectEditor(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Options (Check all that apply)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
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
        const SizedBox(height: 4),
        Text(
          'Players must select all correct answers to earn points.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _optionControllers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, optIdx) {
            final isCorrect = _correctAnswers.contains(optIdx);
            final optColor = _optionColors[optIdx % _optionColors.length];

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isCorrect ? optColor.withValues(alpha: 0.12) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isCorrect ? optColor : theme.colorScheme.outlineVariant,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: isCorrect,
                    activeColor: optColor,
                    onChanged: (_) => _toggleMultiCorrectAnswer(optIdx),
                  ),
                  const SizedBox(width: 4),
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
                  if (_optionControllers.length > 2)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove Option',
                      onPressed: () => _removeOption(optIdx),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 4. Short Text Editor
  Widget _buildShortTextEditor(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Accepted Text Answers',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            if (_optionControllers.length < 5)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Variation', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Matching is case-insensitive. Add alternative spellings or synonyms if applicable.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _optionControllers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, optIdx) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: AppColors.gameGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _optionControllers[optIdx],
                      decoration: InputDecoration(
                        hintText: optIdx == 0 ? 'Primary answer (e.g. Paris)' : 'Variation (e.g. paris)',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_optionControllers.length > 1)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      tooltip: 'Remove Variation',
                      onPressed: () => _removeOption(optIdx),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 5. Numeric Editor
  Widget _buildNumericEditor(ThemeData theme) {
    if (_optionControllers.isEmpty) {
      _optionControllers.add(TextEditingController());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Target Numeric Answer',
          style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the correct number (decimals or integers allowed, e.g. 1969 or 3.14).',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _optionControllers.first,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'e.g. 42 or 3.14',
            prefixIcon: const Icon(Icons.numbers, color: AppColors.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            filled: true,
            fillColor: theme.colorScheme.surface,
          ),
        ),
      ],
    );
  }

  // 6. Ordering Editor
  Widget _buildOrderingEditor(ThemeData theme) {
    const stepLabels = ['1st', '2nd', '3rd', '4th', '5th', '6th'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Correct Sequential Order (1st to Last)',
                style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
            if (_optionControllers.length < 6)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Item', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Enter items in the correct order. They will be automatically scrambled for players.',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _optionControllers.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, optIdx) {
            final color = _optionColors[optIdx % _optionColors.length];
            final label = optIdx < stepLabels.length ? stepLabels[optIdx] : '${optIdx + 1}th';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: _optionControllers[optIdx],
                      decoration: InputDecoration(
                        hintText: 'Item $label in order',
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Move Up',
                    onPressed: optIdx > 0 ? () => _moveOrderingItem(optIdx, optIdx - 1) : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Move Down',
                    onPressed: optIdx < _optionControllers.length - 1
                        ? () => _moveOrderingItem(optIdx, optIdx + 1)
                        : null,
                  ),
                  if (_optionControllers.length > 3)
                    IconButton(
                      icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Remove',
                      onPressed: () => _removeOption(optIdx),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
