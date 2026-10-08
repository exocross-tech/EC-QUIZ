import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../quiz/domain/quiz_question.dart';

enum ContestStatus {
  lobby,
  inProgress,
  ended;

  static ContestStatus fromString(String? val) {
    switch (val) {
      case 'in_progress':
      case 'inProgress':
        return ContestStatus.inProgress;
      case 'ended':
        return ContestStatus.ended;
      case 'lobby':
      default:
        return ContestStatus.lobby;
    }
  }

  String get toDbValue {
    switch (this) {
      case ContestStatus.lobby:
        return 'lobby';
      case ContestStatus.inProgress:
        return 'in_progress';
      case ContestStatus.ended:
        return 'ended';
    }
  }
}

enum ContestStage {
  lobby,
  starting,
  questionActive,
  answerReveal,
  leaderboard,
  podium,
  ended;

  static ContestStage fromString(String? val) {
    switch (val) {
      case 'starting':
        return ContestStage.starting;
      case 'questionActive':
        return ContestStage.questionActive;
      case 'answerReveal':
        return ContestStage.answerReveal;
      case 'leaderboard':
        return ContestStage.leaderboard;
      case 'podium':
        return ContestStage.podium;
      case 'ended':
        return ContestStage.ended;
      case 'lobby':
      default:
        return ContestStage.lobby;
    }
  }
}

class ActiveQuestion {
  final String text;
  final QuestionType type;
  final List<String> options;
  final int timeLimitSeconds;
  final int basePoints;
  final List<String> imagesBase64;
  final String? explanation;
  final List<int> correctAnswers; // Empty during questionActive (anti-cheat), populated during answerReveal

  String? get imageBase64 => imagesBase64.isNotEmpty ? imagesBase64.first : null;

  ActiveQuestion({
    required this.text,
    required this.type,
    required this.options,
    required this.timeLimitSeconds,
    required this.basePoints,
    List<String>? imagesBase64,
    String? imageBase64,
    this.explanation,
    this.correctAnswers = const [],
  }) : imagesBase64 = imagesBase64 ?? (imageBase64 != null ? [imageBase64] : const []);

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'type': type.name,
      'options': options,
      'timeLimitSeconds': timeLimitSeconds,
      'basePoints': basePoints,
      'imagesBase64': imagesBase64,
      if (imageBase64 != null) 'imageBase64': imageBase64,
      if (explanation != null) 'explanation': explanation,
      'correctAnswers': correctAnswers,
    };
  }

  factory ActiveQuestion.fromMap(Map<String, dynamic> map) {
    final rawImages = map['imagesBase64'] as List<dynamic>?;
    final List<String> parsedImages;
    if (rawImages != null) {
      parsedImages = rawImages.map((e) => e.toString()).toList();
    } else if (map['imageBase64'] != null) {
      parsedImages = [map['imageBase64'] as String];
    } else {
      parsedImages = const [];
    }

    return ActiveQuestion(
      text: map['text'] as String? ?? '',
      type: QuestionType.fromString(map['type'] as String?),
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      timeLimitSeconds: (map['timeLimitSeconds'] as num?)?.toInt() ?? 20,
      basePoints: (map['basePoints'] as num?)?.toInt() ?? 1000,
      imagesBase64: parsedImages,
      explanation: map['explanation'] as String?,
      correctAnswers: (map['correctAnswers'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );
  }
}

class Contest {
  final String id;
  final String quizId;
  final String quizTitle;
  final int quizThemeColor;
  final int questionsCount;
  final String hostId;
  final String hostName;
  final String joinCode;
  final String? pin;
  final int maxParticipants;
  final ContestStatus status;
  final ContestStage stage;
  final int currentQuestionIndex;
  final List<String> kickedUserIds;
  final int participantCount;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final ActiveQuestion? activeQuestion;
  final DateTime? questionOpenedAt;
  final Map<String, int> answerDistribution;
  final int answersSubmittedCount;
  final bool isPaused;
  final String? endedReason;

  const Contest({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    this.quizThemeColor = 0xFF6C4AB6,
    required this.questionsCount,
    required this.hostId,
    required this.hostName,
    required this.joinCode,
    this.pin,
    this.maxParticipants = 20,
    this.status = ContestStatus.lobby,
    this.stage = ContestStage.lobby,
    this.currentQuestionIndex = -1,
    this.kickedUserIds = const [],
    this.participantCount = 0,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.activeQuestion,
    this.questionOpenedAt,
    this.answerDistribution = const {},
    this.answersSubmittedCount = 0,
    this.isPaused = false,
    this.endedReason,
  });

  bool get hasPin => pin != null && pin!.trim().isNotEmpty;

  bool get isJoinable =>
      status == ContestStatus.lobby &&
      stage == ContestStage.lobby &&
      participantCount < maxParticipants;

  /// Generates a readable 6-character code avoiding visually ambiguous characters
  static String generateJoinCode() {
    const chars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Contest copyWith({
    String? id,
    String? quizId,
    String? quizTitle,
    int? quizThemeColor,
    int? questionsCount,
    String? hostId,
    String? hostName,
    String? joinCode,
    String? pin,
    int? maxParticipants,
    ContestStatus? status,
    ContestStage? stage,
    int? currentQuestionIndex,
    List<String>? kickedUserIds,
    int? participantCount,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
    ActiveQuestion? activeQuestion,
    DateTime? questionOpenedAt,
    Map<String, int>? answerDistribution,
    int? answersSubmittedCount,
    bool? isPaused,
    String? endedReason,
  }) {
    return Contest(
      id: id ?? this.id,
      quizId: quizId ?? this.quizId,
      quizTitle: quizTitle ?? this.quizTitle,
      quizThemeColor: quizThemeColor ?? this.quizThemeColor,
      questionsCount: questionsCount ?? this.questionsCount,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      joinCode: joinCode ?? this.joinCode,
      pin: pin ?? this.pin,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      status: status ?? this.status,
      stage: stage ?? this.stage,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      kickedUserIds: kickedUserIds ?? List.from(this.kickedUserIds),
      participantCount: participantCount ?? this.participantCount,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      activeQuestion: activeQuestion ?? this.activeQuestion,
      questionOpenedAt: questionOpenedAt ?? this.questionOpenedAt,
      answerDistribution: answerDistribution ?? this.answerDistribution,
      answersSubmittedCount: answersSubmittedCount ?? this.answersSubmittedCount,
      isPaused: isPaused ?? this.isPaused,
      endedReason: endedReason ?? this.endedReason,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quizId': quizId,
      'quizTitle': quizTitle,
      'quizThemeColor': quizThemeColor,
      'questionsCount': questionsCount,
      'hostId': hostId,
      'hostName': hostName,
      'joinCode': joinCode.toUpperCase(),
      'pin': pin?.trim(),
      'maxParticipants': maxParticipants,
      'status': status.toDbValue,
      'stage': stage.name,
      'currentQuestionIndex': currentQuestionIndex,
      'kickedUserIds': kickedUserIds,
      'participantCount': participantCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'activeQuestion': activeQuestion?.toMap(),
      'questionOpenedAt': questionOpenedAt != null ? Timestamp.fromDate(questionOpenedAt!) : null,
      'answerDistribution': answerDistribution,
      'answersSubmittedCount': answersSubmittedCount,
      'isPaused': isPaused,
      'endedReason': endedReason,
    };
  }

  factory Contest.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? (fallback ?? DateTime.now());
      return fallback ?? DateTime.now();
    }

    final kicked = (map['kickedUserIds'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        <String>[];

    final distMap = (map['answerDistribution'] as Map<dynamic, dynamic>?)
            ?.map((k, v) => MapEntry(k.toString(), (v as num).toInt())) ??
        <String, int>{};

    ActiveQuestion? aq;
    if (map['activeQuestion'] != null && map['activeQuestion'] is Map<String, dynamic>) {
      aq = ActiveQuestion.fromMap(map['activeQuestion'] as Map<String, dynamic>);
    }

    return Contest(
      id: docId,
      quizId: map['quizId'] as String? ?? '',
      quizTitle: map['quizTitle'] as String? ?? 'Quiz',
      quizThemeColor: (map['quizThemeColor'] as num?)?.toInt() ?? 0xFF6C4AB6,
      questionsCount: (map['questionsCount'] as num?)?.toInt() ?? 0,
      hostId: map['hostId'] as String? ?? '',
      hostName: map['hostName'] as String? ?? 'Host',
      joinCode: (map['joinCode'] as String? ?? '').toUpperCase(),
      pin: map['pin'] as String?,
      maxParticipants: (map['maxParticipants'] as num?)?.toInt() ?? 20,
      status: ContestStatus.fromString(map['status'] as String?),
      stage: ContestStage.fromString(map['stage'] as String?),
      currentQuestionIndex: (map['currentQuestionIndex'] as num?)?.toInt() ?? -1,
      kickedUserIds: kicked,
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['createdAt']),
      startedAt: map['startedAt'] != null ? parseDate(map['startedAt']) : null,
      endedAt: map['endedAt'] != null ? parseDate(map['endedAt']) : null,
      activeQuestion: aq,
      questionOpenedAt: map['questionOpenedAt'] != null ? parseDate(map['questionOpenedAt']) : null,
      answerDistribution: distMap,
      answersSubmittedCount: (map['answersSubmittedCount'] as num?)?.toInt() ?? 0,
      isPaused: map['isPaused'] as bool? ?? false,
      endedReason: map['endedReason'] as String?,
    );
  }
}
