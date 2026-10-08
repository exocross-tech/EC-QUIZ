import 'package:cloud_firestore/cloud_firestore.dart';

class ContestAnswer {
  final String id;
  final String participantId;
  final String participantName;
  final int questionIndex;
  final List<dynamic> selectedAnswers;
  final DateTime submittedAt;
  final int pointsAwarded;
  final bool isCorrect;
  final double responseTimeSeconds;

  const ContestAnswer({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.questionIndex,
    required this.selectedAnswers,
    required this.submittedAt,
    this.pointsAwarded = 0,
    this.isCorrect = false,
    this.responseTimeSeconds = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'participantId': participantId,
      'participantName': participantName,
      'questionIndex': questionIndex,
      'selectedAnswers': selectedAnswers,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'pointsAwarded': pointsAwarded,
      'isCorrect': isCorrect,
      'responseTimeSeconds': responseTimeSeconds,
    };
  }

  factory ContestAnswer.fromMap(Map<String, dynamic> map, String docId) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return ContestAnswer(
      id: docId,
      participantId: map['participantId'] as String? ?? '',
      participantName: map['participantName'] as String? ?? 'Player',
      questionIndex: (map['questionIndex'] as num?)?.toInt() ?? 0,
      selectedAnswers: (map['selectedAnswers'] as List<dynamic>?) ?? <dynamic>[],
      submittedAt: parseDate(map['submittedAt']),
      pointsAwarded: (map['pointsAwarded'] as num?)?.toInt() ?? 0,
      isCorrect: map['isCorrect'] as bool? ?? false,
      responseTimeSeconds: (map['responseTimeSeconds'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
