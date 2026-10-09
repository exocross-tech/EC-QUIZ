import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizapp/core/constants/app_constants.dart';
import 'package:quizapp/features/splash/presentation/splash_screen.dart';

void main() {
  testWidgets('SplashScreen renders logo, app name, and subtitle cleanly', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Initial frame
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text('LIVE MULTIPLAYER BATTLES'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);

    // Let animation proceed a tick
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text(AppConstants.appName), findsOneWidget);
  });
}
