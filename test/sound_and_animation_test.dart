import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quizapp/core/services/sound_service.dart';
import 'package:quizapp/core/widgets/confetti_overlay.dart';
import 'package:quizapp/core/widgets/game_animations.dart';
import 'package:quizapp/core/widgets/sound_toggle_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SoundService & Settings Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (call) async => null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (call) async => null,
      );
    });


    test('SoundService initializes enabled and handles toggle cleanly', () {
      final service = SoundService();
      expect(service.isEnabled, isTrue);

      service.setEnabled(false);
      expect(service.isEnabled, isFalse);

      service.setEnabled(true);
      expect(service.isEnabled, isTrue);

      // Play methods should never throw even if audio hardware is unavailable in test runner
      expect(() => service.playCorrect(), returnsNormally);
      expect(() => service.playIncorrect(), returnsNormally);
      expect(() => service.playTick(), returnsNormally);
      expect(() => service.playStreak(), returnsNormally);
      expect(() => service.playFanfare(), returnsNormally);
      expect(() => service.playClick(), returnsNormally);

      service.dispose();
    });

    test('SoundSettingNotifier toggles state and updates service', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(soundSettingProvider), isTrue);

      await container.read(soundSettingProvider.notifier).toggleSound();
      expect(container.read(soundSettingProvider), isFalse);

      await container.read(soundSettingProvider.notifier).toggleSound();
      expect(container.read(soundSettingProvider), isTrue);
    });
  });

  group('Animation & Sound Widgets Tests', () {
    testWidgets('SoundToggleButton renders and toggles icon on tap', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SoundToggleButton(),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

      await tester.tap(find.byType(SoundToggleButton));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.volume_off_rounded), findsOneWidget);
    });

    testWidgets('AnimatedStreakFlame renders flame icon and streak count', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedStreakFlame(streak: 4),
          ),
        ),
      );

      expect(find.text('4'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });

    testWidgets('PopIn renders child with bounce animation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PopIn(
              child: Text('CORRECT!'),
            ),
          ),
        ),
      );

      expect(find.text('CORRECT!'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('CORRECT!'), findsOneWidget);
    });

    testWidgets('UrgencyPulse renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UrgencyPulse(
              isUrgent: true,
              child: Text('3s'),
            ),
          ),
        ),
      );

      expect(find.text('3s'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('3s'), findsOneWidget);
    });

    testWidgets('ConfettiOverlay renders child and displays particle canvas', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfettiOverlay(
              child: Text('Podium Celebration'),
            ),
          ),
        ),
      );

      expect(find.text('Podium Celebration'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });
}
