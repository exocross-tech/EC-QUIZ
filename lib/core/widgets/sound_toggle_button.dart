import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sound_service.dart';

class SoundToggleButton extends ConsumerWidget {
  final Color? color;
  final double size;

  const SoundToggleButton({
    super.key,
    this.color,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSoundOn = ref.watch(soundSettingProvider);

    return IconButton(
      tooltip: isSoundOn ? 'Mute sound' : 'Unmute sound',
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Icon(
          isSoundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
          key: ValueKey(isSoundOn),
          size: size,
          color: color ?? (isSoundOn ? null : Colors.grey),
        ),
      ),
      onPressed: () {
        ref.read(soundSettingProvider.notifier).toggleSound();
        if (!isSoundOn) {
          ref.read(soundServiceProvider).playClick();
        }
      },
    );
  }
}
