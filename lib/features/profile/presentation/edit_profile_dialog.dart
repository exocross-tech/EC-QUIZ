import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/avatar_display.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/user_profile.dart';
import 'profile_controller.dart';

class EditProfileDialog extends ConsumerStatefulWidget {
  final UserProfile profile;

  const EditProfileDialog({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends ConsumerState<EditProfileDialog> {
  late TextEditingController _nameController;
  int _selectedTabIndex = 0; // 0: Emoji Presets, 1: Upload Photo

  late String _selectedEmojiId;
  late Color _selectedColor;

  String? _customImageBase64;
  String? _imageSizeFeedback;
  bool _isCompressing = false;

  @override
  void initState() {
    super.initState();
    _selectedTabIndex = widget.profile.avatarType == 'image' ? 1 : 0;
    _nameController = TextEditingController(text: widget.profile.displayName);
    _selectedEmojiId = widget.profile.avatarPresetId;

    // Resolve color
    Color resolved = AppColors.avatarColors.first;
    try {
      final hex = widget.profile.avatarColor.replaceAll('#', '').replaceAll('0x', '');
      final intVal = int.parse(hex, radix: 16);
      resolved = Color(hex.length <= 6 ? (0xFF000000 | intVal) : intVal);
    } catch (_) {}
    _selectedColor = resolved;
    _customImageBase64 = widget.profile.avatarBase64;

    if (_customImageBase64 != null) {
      final sizeKb = ImageUtils.getBase64SizeInKb(_customImageBase64!);
      _imageSizeFeedback = 'Current size: ${sizeKb.toStringAsFixed(1)} KB (under 200 KB)';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() => _isCompressing = true);
      final rawBytes = await picked.readAsBytes();

      // Compress and convert to base64 strictly under 200 KB
      final base64String = await ImageUtils.compressAndEncodeBase64(
        rawBytes,
        maxDimension: 512,
      );
      final sizeKb = ImageUtils.getBase64SizeInKb(base64String);

      setState(() {
        _customImageBase64 = base64String;
        _imageSizeFeedback = 'Compressed to ${sizeKb.toStringAsFixed(1)} KB (limit: 200 KB)';
        _isCompressing = false;
      });
    } on ImageTooLargeException catch (e) {
      setState(() => _isCompressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.gameRed,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCompressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to process image: $e'),
            backgroundColor: AppColors.gameRed,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name cannot be empty')),
      );
      return;
    }

    final isCustomImageTab = _selectedTabIndex == 1;

    if (isCustomImageTab && (_customImageBase64 == null || _customImageBase64!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image or switch to Presets')),
      );
      return;
    }

    final colorHex =
        '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';

    bool success;
    if (isCustomImageTab) {
      try {
        final profileRepo = ref.read(userProfileRepositoryProvider);
        await profileRepo.updateProfileDetails(
          uid: widget.profile.uid,
          displayName: name,
          avatarType: 'image',
          avatarPresetId: 'custom',
          avatarColor: '#6C4AB6',
          avatarBase64: _customImageBase64,
        );
        success = true;
      } catch (_) {
        success = false;
      }
    } else {
      success = await ref.read(profileControllerProvider.notifier).updatePresetAvatar(
            uid: widget.profile.uid,
            displayName: name,
            presetId: _selectedEmojiId,
            colorHex: colorHex,
          );
    }

    if (mounted) {
      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.accent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile.'),
            backgroundColor: AppColors.gameRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(profileControllerProvider).isLoading;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = math.min(680.0, mediaQuery.size.height * 0.9);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: maxHeight,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Profile',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Scrollable body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Display Name
                      CustomTextField(
                        controller: _nameController,
                        label: 'Display Name',
                        hint: 'Nickname',
                        prefixIcon: Icons.edit_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Tab selector
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = 0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 0
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Emoji Presets',
                                      style: TextStyle(
                                        color: _selectedTabIndex == 0
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedTabIndex = 1),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: _selectedTabIndex == 1
                                        ? AppColors.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Upload Photo',
                                      style: TextStyle(
                                        color: _selectedTabIndex == 1
                                            ? Colors.white
                                            : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tab Content
                      if (_selectedTabIndex == 0) ...[
                        // Preset Tab
                        Center(
                          child: AvatarDisplay(
                            avatarType: 'preset',
                            avatarPresetId: _selectedEmojiId,
                            avatarColor:
                                '#${_selectedColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
                            radius: 38,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Choose Emoji',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppConstants.defaultAvatarPresets.map((preset) {
                            final isSelected = _selectedEmojiId == preset.id;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedEmojiId = preset.id),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? AppColors.primary : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  preset.emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'Choose Background Color',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: AppColors.avatarColors.map((color) {
                            final isSelected = _selectedColor == color;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = color),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? Colors.black : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                                    : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ] else ...[
                        // Photo Upload Tab
                        Center(
                          child: Column(
                            children: [
                              if (_isCompressing)
                                const Padding(
                                  padding: EdgeInsets.all(20.0),
                                  child: Column(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 8),
                                      Text(
                                        'Compressing under 200 KB on device...',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                )
                              else if (_customImageBase64 != null)
                                AvatarDisplay(
                                  avatarType: 'image',
                                  avatarBase64: _customImageBase64,
                                  radius: 44,
                                )
                              else
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: Colors.grey.shade200,
                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              const SizedBox(height: 8),
                              if (_imageSizeFeedback != null)
                                Text(
                                  _imageSizeFeedback!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: _isCompressing
                                        ? null
                                        : () => _pickImage(ImageSource.camera),
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('Camera'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton.icon(
                                    onPressed: _isCompressing
                                        ? null
                                        : () => _pickImage(ImageSource.gallery),
                                    icon: const Icon(Icons.photo_library, size: 18),
                                    label: const Text('Gallery'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Images are compressed below 200 KB and stored directly in Firestore (Free Spark Plan).',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Save Button
              CustomButton(
                label: 'Save Changes',
                isLoading: isSaving || _isCompressing,
                onPressed: _handleSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
