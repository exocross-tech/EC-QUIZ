import 'package:flutter_test/flutter_test.dart';
import 'package:quizapp/features/contest/domain/contest.dart';
import 'package:quizapp/features/contest/domain/contest_participant.dart';

void main() {
  group('Contest Domain Tests', () {
    test('generateJoinCode creates readable 6-character uppercase codes without ambiguous chars', () {
      final code1 = Contest.generateJoinCode();
      final code2 = Contest.generateJoinCode();

      expect(code1.length, 6);
      expect(code2.length, 6);
      expect(code1, equals(code1.toUpperCase()));
      expect(code2, equals(code2.toUpperCase()));

      // Ambiguous characters: 0, O, 1, I
      expect(code1.contains('0'), isFalse);
      expect(code1.contains('O'), isFalse);
      expect(code1.contains('1'), isFalse);
      expect(code1.contains('I'), isFalse);

      // Codes should vary
      final set = <String>{};
      for (int i = 0; i < 50; i++) {
        set.add(Contest.generateJoinCode());
      }
      expect(set.length, greaterThan(40));
    });

    test('Serializes and deserializes Contest model with timestamps and status', () {
      final now = DateTime.now();
      final contest = Contest(
        id: 'contest-999',
        quizId: 'quiz-123',
        quizTitle: 'Geography Mania',
        quizThemeColor: 0xFF1368CE,
        questionsCount: 10,
        hostId: 'host-uid-1',
        hostName: 'Captain Quiz',
        joinCode: 'K9X2P4',
        pin: '4321',
        maxParticipants: 15,
        status: ContestStatus.lobby,
        currentQuestionIndex: -1,
        kickedUserIds: const ['kicked-user-1'],
        participantCount: 5,
        createdAt: now,
      );

      expect(contest.hasPin, isTrue);
      expect(contest.isJoinable, isTrue);

      final map = contest.toMap();
      expect(map['id'], 'contest-999');
      expect(map['joinCode'], 'K9X2P4');
      expect(map['pin'], '4321');
      expect(map['status'], 'lobby');
      expect(map['maxParticipants'], 15);
      expect(map['kickedUserIds'], ['kicked-user-1']);

      final reconstructed = Contest.fromMap(map, 'contest-999');
      expect(reconstructed.id, contest.id);
      expect(reconstructed.quizId, contest.quizId);
      expect(reconstructed.quizTitle, contest.quizTitle);
      expect(reconstructed.hostId, contest.hostId);
      expect(reconstructed.hostName, contest.hostName);
      expect(reconstructed.joinCode, contest.joinCode);
      expect(reconstructed.pin, contest.pin);
      expect(reconstructed.maxParticipants, contest.maxParticipants);
      expect(reconstructed.status, ContestStatus.lobby);
      expect(reconstructed.kickedUserIds, ['kicked-user-1']);
      expect(reconstructed.participantCount, 5);
    });

    test('isJoinable enforces lobby status and participant capacity', () {
      final contest = Contest(
        id: 'c-1',
        quizId: 'q-1',
        quizTitle: 'Title',
        questionsCount: 5,
        hostId: 'h-1',
        hostName: 'Host',
        joinCode: 'ABCDEF',
        maxParticipants: 10,
        participantCount: 5,
        status: ContestStatus.lobby,
        createdAt: DateTime.now(),
      );

      // Open lobby with room
      expect(contest.isJoinable, isTrue);

      // Full capacity
      final fullContest = contest.copyWith(participantCount: 10);
      expect(fullContest.isJoinable, isFalse);

      // In progress
      final inProgressContest = contest.copyWith(status: ContestStatus.inProgress);
      expect(inProgressContest.isJoinable, isFalse);

      // Ended
      final endedContest = contest.copyWith(status: ContestStatus.ended);
      expect(endedContest.isJoinable, isFalse);
    });
  });

  group('ContestParticipant Domain Tests', () {
    test('Serializes and deserializes ContestParticipant correctly', () {
      final now = DateTime.now();
      final participant = ContestParticipant(
        id: 'player-1',
        displayName: 'Speedy Fox',
        avatarType: 'preset',
        avatarPresetId: 'fox',
        avatarColor: '#FFA602',
        joinedAt: now,
        totalScore: 1250,
      );

      final map = participant.toMap();
      expect(map['id'], 'player-1');
      expect(map['displayName'], 'Speedy Fox');
      expect(map['avatarPresetId'], 'fox');
      expect(map['totalScore'], 1250);

      final reconstructed = ContestParticipant.fromMap(map, 'player-1');
      expect(reconstructed.id, participant.id);
      expect(reconstructed.displayName, participant.displayName);
      expect(reconstructed.avatarPresetId, participant.avatarPresetId);
      expect(reconstructed.avatarColor, participant.avatarColor);
      expect(reconstructed.totalScore, 1250);
    });
  });
}
