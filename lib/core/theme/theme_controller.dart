import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemePreferenceKey = 'user_theme_mode';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Default to Light mode on all devices
    _loadPersistedTheme();
    return ThemeMode.light;
  }

  Future<void> _loadPersistedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_kThemePreferenceKey);
      if (savedMode == 'dark') {
        state = ThemeMode.dark;
      } else if (savedMode == 'light') {
        state = ThemeMode.light;
      }
      // If null, state stays ThemeMode.light by default
    } catch (_) {
      // In tests or if storage is unavailable, default remains ThemeMode.light
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _kThemePreferenceKey,
        mode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    final nextMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(nextMode);
  }
}

final themeModeControllerProvider =
    NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
