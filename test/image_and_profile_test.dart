import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:quizapp/core/utils/image_utils.dart';
import 'package:quizapp/features/profile/domain/user_profile.dart';

void main() {
  group('UserProfile Model Tests', () {
    test('Serializes to and from Map correctly', () {
      final profile = UserProfile(
        uid: 'user_123',
        email: 'player@example.com',
        displayName: 'MegaPlayer',
        avatarType: 'preset',
        avatarPresetId: 'rocket',
        avatarColor: '#1368CE',
        contestsPlayed: 5,
        totalPoints: 4200,
        wins: 3,
      );

      final map = profile.toMap();
      expect(map['displayName'], equals('MegaPlayer'));
      expect(map['avatarPresetId'], equals('rocket'));
      expect(map['totalPoints'], equals(4200));

      final deserialized = UserProfile.fromMap(map, 'user_123');
      expect(deserialized.uid, equals('user_123'));
      expect(deserialized.displayName, equals('MegaPlayer'));
      expect(deserialized.wins, equals(3));
    });

    test('Computes win rate dynamically from contestsPlayed and wins', () {
      final freshProfile = UserProfile(
        uid: 'user_fresh',
        email: 'fresh@example.com',
        displayName: 'Newbie',
        contestsPlayed: 0,
        wins: 0,
      );
      final winRate0 = freshProfile.contestsPlayed > 0
          ? '${((freshProfile.wins / freshProfile.contestsPlayed) * 100).toStringAsFixed(0)}%'
          : '0%';
      expect(winRate0, equals('0%'));

      final updatedProfile = freshProfile.copyWith(
        contestsPlayed: 10,
        totalPoints: 12500,
        wins: 7,
      );
      final winRateUpdated = updatedProfile.contestsPlayed > 0
          ? '${((updatedProfile.wins / updatedProfile.contestsPlayed) * 100).toStringAsFixed(0)}%'
          : '0%';
      expect(winRateUpdated, equals('70%'));
      expect(updatedProfile.totalPoints, equals(12500));
    });
  });

  group('ImageUtils Compression Tests', () {
    test('Compresses raw image bytes and returns base64 string under 200 KB', () async {
      // Create a dummy 400x400 image in memory
      final testImage = img.Image(width: 400, height: 400);
      img.fill(testImage, color: img.ColorRgb8(100, 150, 200));
      final rawJpg = img.encodeJpg(testImage);

      final base64String = await ImageUtils.compressAndEncodeBase64(rawJpg);
      expect(base64String.isNotEmpty, isTrue);

      final sizeKb = ImageUtils.getBase64SizeInKb(base64String);
      expect(sizeKb, lessThanOrEqualTo(200.0));

      // Verify decoding back to bytes
      final decodedBytes = ImageUtils.base64ToBytes(base64String);
      expect(decodedBytes, isNotNull);
      expect(decodedBytes!.isNotEmpty, isTrue);
    });

    test('base64ToBytes correctly strips data URI prefixes', () {
      const sample = 'SGVsbG8gV29ybGQ='; // "Hello World"
      const withPrefix = 'data:image/jpeg;base64,$sample';

      final bytes = ImageUtils.base64ToBytes(withPrefix);
      expect(bytes, isNotNull);
      expect(utf8.decode(bytes!), equals('Hello World'));
    });
  });
}
