import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'core/routing/app_router.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Guard against known Flutter Web engine viewport assertions on browser resize / keyboard dismiss
  PlatformDispatcher.instance.onError = (error, stack) {
    if (error.toString().contains('ViewInsets cannot be negative')) {
      return true; // handled
    }
    return false;
  };

  FlutterError.onError = (FlutterErrorDetails details) {
    if (details.exceptionAsString().contains('ViewInsets cannot be negative')) {
      return;
    }
    FlutterError.presentError(details);
  };

  bool firebaseInitialized = false;
  String? initError;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
  } catch (e) {
    initError = e.toString();
  }

  runApp(
    ProviderScope(
      child: QuizApp(
        firebaseInitialized: firebaseInitialized,
        initError: initError,
      ),
    ),
  );
}

class QuizApp extends ConsumerWidget {
  final bool firebaseInitialized;
  final String? initError;

  const QuizApp({
    super.key,
    required this.firebaseInitialized,
    this.initError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeControllerProvider);

    if (!firebaseInitialized) {
      return MaterialApp(
        title: AppConstants.appName,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        home: _FirebaseSetupRequiredScreen(error: initError),
      );
    }

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}

class _FirebaseSetupRequiredScreen extends StatelessWidget {
  final String? error;

  const _FirebaseSetupRequiredScreen({this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Configuration Needed'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.cloud_sync, size: 72, color: Colors.amber),
              ),
              const SizedBox(height: 16),
              const Text(
                'Connect to Your Firebase Project',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'To start testing Phase 1 authentication and profile storage, connect your free Firebase project:',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 18),
              _buildStep(
                '1',
                'Go to Firebase Console (console.firebase.google.com) and create a free project.',
              ),
              _buildStep(
                '2',
                'Add an Android app with package name:\ncom.private.quizapp',
              ),
              _buildStep(
                '3',
                'Download google-services.json and place it at:\nandroid/app/google-services.json',
              ),
              _buildStep(
                '4',
                'In Firebase Console, enable Authentication -> Email/Password and Cloud Firestore in test mode.',
              ),
              _buildStep(
                '5',
                'Update lib/firebase_options.dart with your project keys or run `flutterfire configure`.',
              ),
              if (error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    'Initialization details:\n$error',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: Colors.red.shade900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: const Color(0xFF6C4AB6),
            child: Text(
              num,
              style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
