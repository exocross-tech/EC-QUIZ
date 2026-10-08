import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_check_stub.dart'
    if (dart.library.io) 'platform_check_io.dart';

const String _kSoundEnabledPref = 'quiz_sound_enabled';

/// Sound effects service managing playback and mute preference.
class SoundService {
  AudioPlayer? _player;
  bool _enabled = true;

  SoundService({AudioPlayer? player}) : _player = player {
    _init();
  }

  bool get isEnabled => _enabled;

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kSoundEnabledPref) ?? true;
    } catch (_) {}
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool(_kSoundEnabledPref, enabled);
    }).catchError((_) {});
  }

  Future<void> _playAsset(String path) async {
    if (!_enabled || isFlutterTest) return;
    try {
      _player ??= AudioPlayer();
      await _player?.stop();
      await _player?.play(AssetSource(path));
    } catch (_) {
      // Gracefully silent if audio driver is unavailable on specific platform/test
    }
  }



  void playCorrect() => _playAsset('audio/correct.wav');
  void playIncorrect() => _playAsset('audio/incorrect.wav');
  void playTick() => _playAsset('audio/tick.wav');
  void playStreak() => _playAsset('audio/streak.wav');
  void playFanfare() => _playAsset('audio/fanfare.wav');
  void playClick() => _playAsset('audio/click.wav');

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
  }

}

/// Provider for the singleton SoundService
final soundServiceProvider = Provider<SoundService>((ref) {
  final service = SoundService();
  ref.onDispose(service.dispose);
  return service;
});

/// Reactive sound toggle notifier
class SoundSettingNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadPreference();
    return true;
  }

  Future<void> _loadPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final val = prefs.getBool(_kSoundEnabledPref) ?? true;
      state = val;
      ref.read(soundServiceProvider).setEnabled(val);
    } catch (_) {}
  }

  Future<void> toggleSound() async {
    final next = !state;
    state = next;
    ref.read(soundServiceProvider).setEnabled(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSoundEnabledPref, next);
  }
}

final soundSettingProvider =
    NotifierProvider<SoundSettingNotifier, bool>(SoundSettingNotifier.new);
