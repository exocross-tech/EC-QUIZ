import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import 'quiz_question.dart';

class Quiz {
  final String id;
  final String creatorId;
  final String creatorName;
  final String title;
  final String description;
  final int themeColor;
  final bool isDraft;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Quiz({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    required this.title,
    required this.description,
    this.themeColor = 0xFF6C4AB6,
    this.isDraft = true,
    required this.questions,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory to start a brand new blank quiz draft
  factory Quiz.createDraft({
    required String creatorId,
    required String creatorName,
  }) {
    final now = DateTime.now();
    return Quiz(
      id: const Uuid().v4(),
      creatorId: creatorId,
      creatorName: creatorName,
      title: '',
      description: '',
      themeColor: 0xFF6C4AB6,
      isDraft: true,
      questions: const [],
      createdAt: now,
      updatedAt: now,
    );
  }

  int get questionsCount => questions.length;

  int get totalTimeSeconds =>
      questions.fold(0, (total, q) => total + q.timeLimitSeconds);

  int get totalPoints => questions.fold(0, (total, q) => total + q.basePoints);

  /// Computes the exact UTF-8 byte payload size of this quiz when stored in Firestore
  int get estimatedSizeBytes {
    try {
      final jsonStr = jsonEncode(toMap());
      return utf8.encode(jsonStr).length;
    } catch (_) {
      // Fallback manual estimate
      int size = 1024; // Metadata buffer
      for (final q in questions) {
        size += q.estimatedSizeBytes;
      }
      return size;
    }
  }

  /// Whether this quiz safely stays within the 1 MB Spark plan document ceiling
  bool get isUnderDocLimit => estimatedSizeBytes <= AppConstants.maxDocSizeBytes;

  /// Returns null if valid for publishing, or an informative error message if invalid
  String? get publishValidationError {
    if (title.trim().isEmpty) {
      return 'Please enter a quiz title.';
    }
    if (questions.isEmpty) {
      return 'A published quiz must contain at least 1 question.';
    }
    for (int i = 0; i < questions.length; i++) {
      final qErr = questions[i].validationError;
      if (qErr != null) {
        return 'Question ${i + 1}: $qErr';
      }
    }
    if (!isUnderDocLimit) {
      final kb = (estimatedSizeBytes / 1024).toStringAsFixed(1);
      return 'Quiz size ($kb KB) exceeds the 1 MB Firestore limit. Please remove or compress some images.';
    }
    return null;
  }

  bool get isValidForPublish => publishValidationError == null;

  Quiz copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? title,
    String? description,
    int? themeColor,
    bool? isDraft,
    List<QuizQuestion>? questions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quiz(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      title: title ?? this.title,
      description: description ?? this.description,
      themeColor: themeColor ?? this.themeColor,
      isDraft: isDraft ?? this.isDraft,
      questions: questions ?? List.from(this.questions),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Clones the quiz for reusability with a new ID
  Quiz duplicate({
    required String newCreatorId,
    required String newCreatorName,
  }) {
    final now = DateTime.now();
    return Quiz(
      id: const Uuid().v4(),
      creatorId: newCreatorId,
      creatorName: newCreatorName,
      title: '$title (Copy)',
      description: description,
      themeColor: themeColor,
      isDraft: true,
      questions: questions.map((q) => q.duplicate()).toList(),
      createdAt: now,
      updatedAt: now,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'creatorId': creatorId,
      'creatorName': creatorName,
      'title': title.trim(),
      'description': description.trim(),
      'themeColor': themeColor,
      'isDraft': isDraft,
      'questionsCount': questionsCount,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Quiz.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawQuestions = map['questions'] as List<dynamic>? ?? [];
    final questionsList = rawQuestions
        .whereType<Map<String, dynamic>>()
        .map((qMap) => QuizQuestion.fromMap(qMap))
        .toList();

    return Quiz(
      id: docId,
      creatorId: map['creatorId'] as String? ?? '',
      creatorName: map['creatorName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      themeColor: (map['themeColor'] as num?)?.toInt() ?? 0xFF6C4AB6,
      isDraft: map['isDraft'] as bool? ?? false,
      questions: questionsList,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
