import '../domain/user_profile.dart';

abstract class UserProfileRepository {
  /// Stream profile document for a user
  Stream<UserProfile?> watchProfile(String uid);

  /// Fetch profile once
  Future<UserProfile?> getProfile(String uid);

  /// Create or update profile
  Future<void> saveProfile(UserProfile profile);

  /// Update only display name & avatar settings
  Future<void> updateProfileDetails({
    required String uid,
    required String displayName,
    required String avatarType,
    required String avatarPresetId,
    required String avatarColor,
    String? avatarBase64,
  });

  /// Increment game stats (contests played, score, wins)
  Future<void> recordGameResults({
    required String uid,
    required int pointsEarned,
    required bool won,
  });
}
