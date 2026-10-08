import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final int currentQuestionIndex;
  final List<String> kickedUserIds;
  final int participantCount;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;

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
    this.currentQuestionIndex = -1,
    this.kickedUserIds = const [],
    this.participantCount = 0,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
  });

  bool get hasPin => pin != null && pin!.trim().isNotEmpty;

  bool get isJoinable =>
      status == ContestStatus.lobby && participantCount < maxParticipants;

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
    int? currentQuestionIndex,
    List<String>? kickedUserIds,
    int? participantCount,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? endedAt,
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
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      kickedUserIds: kickedUserIds ?? List.from(this.kickedUserIds),
      participantCount: participantCount ?? this.participantCount,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
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
      'currentQuestionIndex': currentQuestionIndex,
      'kickedUserIds': kickedUserIds,
      'participantCount': participantCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
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
      currentQuestionIndex: (map['currentQuestionIndex'] as num?)?.toInt() ?? -1,
      kickedUserIds: kicked,
      participantCount: (map['participantCount'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['createdAt']),
      startedAt: map['startedAt'] != null ? parseDate(map['startedAt']) : null,
      endedAt: map['endedAt'] != null ? parseDate(map['endedAt']) : null,
    );
  }
}
