import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_constants.dart';
import '../utils/image_utils.dart';

class AvatarDisplay extends StatelessWidget {
  final String avatarType; // 'preset' or 'image'
  final String? avatarPresetId;
  final String? avatarColor;
  final String? avatarBase64;
  final double radius;
  final VoidCallback? onTap;

  const AvatarDisplay({
    super.key,
    required this.avatarType,
    this.avatarPresetId,
    this.avatarColor,
    this.avatarBase64,
    this.radius = 28,
    this.onTap,
  });

  Color _resolveColor() {
    if (avatarColor != null && avatarColor!.isNotEmpty) {
      try {
        final hexStr = avatarColor!.replaceAll('#', '').replaceAll('0x', '');
        final intVal = int.parse(hexStr, radix: 16);
        return Color(hexStr.length <= 6 ? (0xFF000000 | intVal) : intVal);
      } catch (_) {}
    }
    return AppColors.primary;
  }

  String _resolveEmoji() {
    if (avatarPresetId != null) {
      final found = AppConstants.defaultAvatarPresets.where(
        (p) => p.id == avatarPresetId,
      );
      if (found.isNotEmpty) return found.first.emoji;
    }
    return '🦁'; // default
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (avatarType == 'image' && avatarBase64 != null && avatarBase64!.isNotEmpty) {
      final imageBytes = ImageUtils.base64ToBytes(avatarBase64);
      if (imageBytes != null) {
        content = CircleAvatar(
          radius: radius,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: MemoryImage(imageBytes),
        );
      } else {
        content = _buildPresetAvatar();
      }
    } else {
      content = _buildPresetAvatar();
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }
    return content;
  }

  Widget _buildPresetAvatar() {
    final bgColor = _resolveColor();
    final emoji = _resolveEmoji();

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: radius * 1.05,
        ),
      ),
    );
  }
}
