import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quizapp/main.dart';

void main() {
  testWidgets('QuizApp mounts cleanly with Firebase setup fallback screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: QuizApp(
          firebaseInitialized: false,
          initError: 'Demo test mode',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Firebase Configuration Needed'), findsOneWidget);
    expect(find.text('Connect to Your Firebase Project'), findsOneWidget);
  });
}
