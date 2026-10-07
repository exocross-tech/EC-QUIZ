import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/image_utils.dart';
import '../domain/user_profile.dart';
import 'user_profile_repository.dart';

class FirestoreUserProfileRepository implements UserProfileRepository {
  final FirebaseFirestore _firestore;

  FirestoreUserProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  @override
  Stream<UserProfile?> watchProfile(String uid) {
    return _usersRef.doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromMap(doc.data()!, doc.id);
    });
  }

  @override
  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _usersRef.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return UserProfile.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<void> saveProfile(UserProfile profile) async {
    // Safety check on base64 image size to avoid exceeding 1MB doc limit
    if (profile.avatarBase64 != null) {
      final sizeKb = ImageUtils.getBase64SizeInKb(profile.avatarBase64!);
      if (sizeKb > (AppConstants.maxImageSizeBytes / 1024)) {
        throw ImageTooLargeException(
          'Avatar image size (${sizeKb.toStringAsFixed(1)} KB) exceeds the 200 KB limit for Firestore.',
        );
      }
    }

    final data = profile.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _usersRef.doc(profile.uid).set(data, SetOptions(merge: true));
  }

  @override
  Future<void> updateProfileDetails({
    required String uid,
    required String displayName,
    required String avatarType,
    required String avatarPresetId,
    required String avatarColor,
    String? avatarBase64,
  }) async {
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      final sizeKb = ImageUtils.getBase64SizeInKb(avatarBase64);
      if (sizeKb > (AppConstants.maxImageSizeBytes / 1024)) {
        throw ImageTooLargeException(
          'Avatar image size (${sizeKb.toStringAsFixed(1)} KB) exceeds the 200 KB limit for Firestore.',
        );
      }
    }

    await _usersRef.doc(uid).update({
      'displayName': displayName.trim(),
      'avatarType': avatarType,
      'avatarPresetId': avatarPresetId,
      'avatarColor': avatarColor,
      'avatarBase64': avatarBase64,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> recordGameResults({
    required String uid,
    required int pointsEarned,
    required bool won,
  }) async {
    await _usersRef.doc(uid).update({
      'contestsPlayed': FieldValue.increment(1),
      'totalPoints': FieldValue.increment(pointsEarned),
      'wins': FieldValue.increment(won ? 1 : 0),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
