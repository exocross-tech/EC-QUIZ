import 'dart:convert';
import 'package:uuid/uuid.dart';

enum QuestionType {
  multipleChoice,
  multipleSelect,
  trueFalse,
  shortText,
  numeric,
  ordering;

  String get label {
    switch (this) {
      case QuestionType.multipleChoice:
        return 'Multiple Choice';
      case QuestionType.multipleSelect:
        return 'Multiple Select';
      case QuestionType.trueFalse:
        return 'True / False';
      case QuestionType.shortText:
        return 'Short Text';
      case QuestionType.numeric:
        return 'Numeric';
      case QuestionType.ordering:
        return 'Ordering';
    }
  }

  static QuestionType fromString(String? typeStr) {
    return QuestionType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => QuestionType.multipleChoice,
    );
  }
}

class QuizQuestion {
  final String id;
  final String text;
  final QuestionType type;
  final List<String> options;
  final List<int> correctAnswers;
  final int timeLimitSeconds;
  final int basePoints;
  final String? explanation;
  final String? imageBase64;

  const QuizQuestion({
    required this.id,
    required this.text,
    this.type = QuestionType.multipleChoice,
    required this.options,
    required this.correctAnswers,
    this.timeLimitSeconds = 20,
    this.basePoints = 1000,
    this.explanation,
    this.imageBase64,
  });

  /// Factory to generate a fresh, blank multiple-choice question
  factory QuizQuestion.empty() {
    return QuizQuestion(
      id: const Uuid().v4(),
      text: '',
      type: QuestionType.multipleChoice,
      options: const ['', '', '', ''],
      correctAnswers: const [0],
      timeLimitSeconds: 20,
      basePoints: 1000,
      explanation: null,
      imageBase64: null,
    );
  }

  QuizQuestion copyWith({
    String? id,
    String? text,
    QuestionType? type,
    List<String>? options,
    List<int>? correctAnswers,
    int? timeLimitSeconds,
    int? basePoints,
    String? explanation,
    String? imageBase64,
    bool clearImage = false,
  }) {
    return QuizQuestion(
      id: id ?? this.id,
      text: text ?? this.text,
      type: type ?? this.type,
      options: options ?? List.from(this.options),
      correctAnswers: correctAnswers ?? List.from(this.correctAnswers),
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      basePoints: basePoints ?? this.basePoints,
      explanation: explanation ?? this.explanation,
      imageBase64: clearImage ? null : (imageBase64 ?? this.imageBase64),
    );
  }

  /// Duplicates this question with a new unique UUID
  QuizQuestion duplicate() {
    return copyWith(
      id: const Uuid().v4(),
      text: text.isNotEmpty ? '$text (Copy)' : '',
    );
  }

  /// Validates if this question is ready for an active contest/publish
  bool get isValidForPublish => validationError == null;

  String? get validationError {
    if (text.trim().isEmpty) {
      return 'Question text cannot be empty.';
    }
    if (options.length < 2) {
      return 'Must have at least 2 options.';
    }
    for (int i = 0; i < options.length; i++) {
      if (options[i].trim().isEmpty) {
        return 'Option ${i + 1} cannot be empty.';
      }
    }
    if (correctAnswers.isEmpty) {
      return 'Must select at least one correct answer.';
    }
    for (final answerIndex in correctAnswers) {
      if (answerIndex < 0 || answerIndex >= options.length) {
        return 'Invalid correct answer selection.';
      }
    }
    return null;
  }

  /// Estimates the serialized size in bytes for Firestore document quota checking
  int get estimatedSizeBytes {
    int size = 0;
    size += utf8.encode(id).length;
    size += utf8.encode(text).length;
    size += utf8.encode(type.name).length;
    for (final opt in options) {
      size += utf8.encode(opt).length;
    }
    size += correctAnswers.length * 4;
    size += 8; // timeLimitSeconds + basePoints
    if (explanation != null) {
      size += utf8.encode(explanation!).length;
    }
    if (imageBase64 != null) {
      size += imageBase64!.length;
    }
    return size;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text.trim(),
      'type': type.name,
      'options': options.map((e) => e.trim()).toList(),
      'correctAnswers': correctAnswers,
      'timeLimitSeconds': timeLimitSeconds,
      'basePoints': basePoints,
      'explanation': explanation?.trim(),
      'imageBase64': imageBase64,
    };
  }

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as String? ?? const Uuid().v4(),
      text: map['text'] as String? ?? '',
      type: QuestionType.fromString(map['type'] as String?),
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      correctAnswers: (map['correctAnswers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          <int>[],
      timeLimitSeconds: (map['timeLimitSeconds'] as num?)?.toInt() ?? 20,
      basePoints: (map['basePoints'] as num?)?.toInt() ?? 1000,
      explanation: map['explanation'] as String?,
      imageBase64: map['imageBase64'] as String?,
    );
  }
}
