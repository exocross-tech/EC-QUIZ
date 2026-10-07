import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/utils/image_utils.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileController extends AsyncNotifier<void> {
  final ImagePicker _imagePicker = ImagePicker();

  @override
  FutureOr<void> build() {
    return null;
  }

  /// Updates profile with a preset emoji avatar
  Future<bool> updatePresetAvatar({
    required String uid,
    required String displayName,
    required String presetId,
    required String colorHex,
  }) async {
    state = const AsyncValue.loading();
    try {
      final profileRepo = ref.read(userProfileRepositoryProvider);
      await profileRepo.updateProfileDetails(
        uid: uid,
        displayName: displayName,
        avatarType: 'preset',
        avatarPresetId: presetId,
        avatarColor: colorHex,
        avatarBase64: null,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  /// Picks an image from camera or gallery, compresses it below 200 KB, and updates profile
  Future<bool> pickAndUploadAvatarImage({
    required String uid,
    required String displayName,
    required ImageSource source,
  }) async {
    state = const AsyncValue.loading();
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) {
        state = const AsyncValue.data(null);
        return false;
      }

      final rawBytes = await pickedFile.readAsBytes();
      // Compress and convert to base64 strictly under 200 KB
      final base64String = await ImageUtils.compressAndEncodeBase64(
        rawBytes,
        maxDimension: 512,
      );

      final profileRepo = ref.read(userProfileRepositoryProvider);
      await profileRepo.updateProfileDetails(
        uid: uid,
        displayName: displayName,
        avatarType: 'image',
        avatarPresetId: 'custom',
        avatarColor: '#6C4AB6',
        avatarBase64: base64String,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final profileControllerProvider =
    AsyncNotifierProvider<ProfileController, void>(ProfileController.new);
