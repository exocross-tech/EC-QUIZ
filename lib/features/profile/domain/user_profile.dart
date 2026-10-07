import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final String avatarType; // 'preset' or 'image'
  final String avatarPresetId; // e.g. 'lion', 'fox', 'rocket'
  final String avatarColor; // hex string e.g. '#6C4AB6'
  final String? avatarBase64;
  final int contestsPlayed;
  final int totalPoints;
  final int wins;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarType = 'preset',
    this.avatarPresetId = 'lion',
    this.avatarColor = '#6C4AB6',
    this.avatarBase64,
    this.contestsPlayed = 0,
    this.totalPoints = 0,
    this.wins = 0,
    this.createdAt,
    this.updatedAt,
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? avatarType,
    String? avatarPresetId,
    String? avatarColor,
    String? avatarBase64,
    int? contestsPlayed,
    int? totalPoints,
    int? wins,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarType: avatarType ?? this.avatarType,
      avatarPresetId: avatarPresetId ?? this.avatarPresetId,
      avatarColor: avatarColor ?? this.avatarColor,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      contestsPlayed: contestsPlayed ?? this.contestsPlayed,
      totalPoints: totalPoints ?? this.totalPoints,
      wins: wins ?? this.wins,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarType': avatarType,
      'avatarPresetId': avatarPresetId,
      'avatarColor': avatarColor,
      'avatarBase64': avatarBase64,
      'contestsPlayed': contestsPlayed,
      'totalPoints': totalPoints,
      'wins': wins,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return UserProfile(
      uid: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? 'Player',
      avatarType: map['avatarType'] as String? ?? 'preset',
      avatarPresetId: map['avatarPresetId'] as String? ?? 'lion',
      avatarColor: map['avatarColor'] as String? ?? '#6C4AB6',
      avatarBase64: map['avatarBase64'] as String?,
      contestsPlayed: (map['contestsPlayed'] as num?)?.toInt() ?? 0,
      totalPoints: (map['totalPoints'] as num?)?.toInt() ?? 0,
      wins: (map['wins'] as num?)?.toInt() ?? 0,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
    );
  }
}
