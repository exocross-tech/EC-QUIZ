import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'platform_check_stub.dart'
    if (dart.library.io) 'platform_check_io.dart';

const String _kSoundEnabledPref = 'quiz_sound_enabled';

/// Sound effects service managing playback, BGM loop, and mute preference.
class SoundService {
  AudioPlayer? _sfxPlayer;
  AudioPlayer? _bgmPlayer;
  bool _enabled = true;
  bool _bgmSuppressed = false;
  bool _isBgmPlaying = false;

  SoundService({AudioPlayer? sfxPlayer, AudioPlayer? bgmPlayer}) {
    _sfxPlayer = sfxPlayer;
    _bgmPlayer = bgmPlayer;
    _init();
  }

  bool get isEnabled => _enabled;
  bool get isBgmSuppressed => _bgmSuppressed;

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

    if (!enabled) {
      pauseBgm();
      _sfxPlayer?.stop().catchError((_) {});
    } else if (!_bgmSuppressed) {
      resumeBgm();
    }
  }

  // --- Background Music (BGM) Controls ---

  Future<void> startBgm() async {
    if (!_enabled || _bgmSuppressed || isFlutterTest) return;
    try {
      _bgmPlayer ??= AudioPlayer();
      await _bgmPlayer?.setReleaseMode(ReleaseMode.loop);
      await _bgmPlayer?.setVolume(0.25);
      await _bgmPlayer?.stop();
      await _bgmPlayer?.play(AssetSource('audio/bgm_loop.wav'));
      _isBgmPlaying = true;
    } catch (_) {
      // Gracefully silent if platform audio driver unavailable
    }
  }

  Future<void> pauseBgm() async {
    if (isFlutterTest) return;
    try {
      await _bgmPlayer?.pause();
      _isBgmPlaying = false;
    } catch (_) {}
  }

  Future<void> resumeBgm() async {
    if (!_enabled || _bgmSuppressed || isFlutterTest) return;
    if (_bgmPlayer == null || !_isBgmPlaying) {
      startBgm();
    }
  }

  Future<void> stopBgm() async {
    if (isFlutterTest) return;
    try {
      await _bgmPlayer?.stop();
      _isBgmPlaying = false;
    } catch (_) {}
  }

  void setBgmSuppressed(bool suppressed) {
    if (_bgmSuppressed == suppressed) return;
    _bgmSuppressed = suppressed;
    if (suppressed) {
      pauseBgm();
    } else if (_enabled) {
      resumeBgm();
    }
  }

  // --- Sound Effects (SFX) ---

  Future<void> _playAsset(String path) async {
    if (!_enabled || isFlutterTest) return;
    try {
      _sfxPlayer ??= AudioPlayer();
      await _sfxPlayer?.stop();
      await _sfxPlayer?.play(AssetSource(path));
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
      _sfxPlayer?.dispose();
      _bgmPlayer?.dispose();
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

  Future<void> setSound(bool enabled) async {
    if (state == enabled) return;
    state = enabled;
    ref.read(soundServiceProvider).setEnabled(enabled);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kSoundEnabledPref, enabled);
    } catch (_) {}
  }

  Future<void> toggleSound() async {
    await setSound(!state);
  }
}

final soundSettingProvider =
    NotifierProvider<SoundSettingNotifier, bool>(SoundSettingNotifier.new);
