import 'package:cloud_firestore/cloud_firestore.dart';

class ContestParticipant {
  final String id;
  final String displayName;
  final String avatarType;
  final String? avatarPresetId;
  final String? avatarColor;
  final String? avatarBase64;
  final DateTime joinedAt;
  final int totalScore;
  final int lastPointsEarned;
  final int streak;
  final bool? isCorrectLastAnswer;

  const ContestParticipant({
    required this.id,
    required this.displayName,
    this.avatarType = 'preset',
    this.avatarPresetId,
    this.avatarColor,
    this.avatarBase64,
    required this.joinedAt,
    this.totalScore = 0,
    this.lastPointsEarned = 0,
    this.streak = 0,
    this.isCorrectLastAnswer,
  });

  ContestParticipant copyWith({
    String? id,
    String? displayName,
    String? avatarType,
    String? avatarPresetId,
    String? avatarColor,
    String? avatarBase64,
    DateTime? joinedAt,
    int? totalScore,
    int? lastPointsEarned,
    int? streak,
    bool? isCorrectLastAnswer,
  }) {
    return ContestParticipant(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarType: avatarType ?? this.avatarType,
      avatarPresetId: avatarPresetId ?? this.avatarPresetId,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      joinedAt: joinedAt ?? this.joinedAt,
      totalScore: totalScore ?? this.totalScore,
      lastPointsEarned: lastPointsEarned ?? this.lastPointsEarned,
      streak: streak ?? this.streak,
      isCorrectLastAnswer: isCorrectLastAnswer ?? this.isCorrectLastAnswer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'avatarType': avatarType,
      'avatarPresetId': avatarPresetId,
      'avatarColor': avatarColor,
      'avatarBase64': avatarBase64,
      'joinedAt': Timestamp.fromDate(joinedAt),
      'totalScore': totalScore,
      'lastPointsEarned': lastPointsEarned,
      'streak': streak,
      'isCorrectLastAnswer': isCorrectLastAnswer,
    };
  }

  factory ContestParticipant.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ContestParticipant(
      id: docId,
      displayName: map['displayName'] as String? ?? 'Player',
      avatarType: map['avatarType'] as String? ?? 'preset',
      avatarPresetId: map['avatarPresetId'] as String?,
      avatarColor: map['avatarColor'] as String?,
      avatarBase64: map['avatarBase64'] as String?,
      joinedAt: parseDate(map['joinedAt']),
      totalScore: (map['totalScore'] as num?)?.toInt() ?? 0,
      lastPointsEarned: (map['lastPointsEarned'] as num?)?.toInt() ?? 0,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      isCorrectLastAnswer: map['isCorrectLastAnswer'] as bool?,
    );
  }
}
