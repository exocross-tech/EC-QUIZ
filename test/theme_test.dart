import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizapp/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeController defaults to ThemeMode.light on all devices', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final themeMode = container.read(themeModeControllerProvider);
      expect(themeMode, ThemeMode.light);
    });

    test('ThemeController toggles between light and dark modes', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(themeModeControllerProvider), ThemeMode.light);

      await container.read(themeModeControllerProvider.notifier).toggleTheme();
      expect(container.read(themeModeControllerProvider), ThemeMode.dark);

      await container.read(themeModeControllerProvider.notifier).toggleTheme();
      expect(container.read(themeModeControllerProvider), ThemeMode.light);
    });

    test('ThemeController persists preference to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(themeModeControllerProvider.notifier).setThemeMode(ThemeMode.dark);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_theme_mode'), 'dark');
    });
  });
}
