// File generated for quizapp project configuration
// Replace these values with your actual Firebase project values from Firebase Console,
// or run `flutterfire configure`.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Placeholder Android Firebase configuration for com.private.quizapp.
  // Update with your actual credentials from Firebase Console -> Project Settings -> General -> Your apps
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCas217mlZ6GLvtKsdezE2WmHt-R217Kco',
    appId: '1:179431012469:android:bdc479de9e6196e026e03c',
    messagingSenderId: '179431012469',
    projectId: 'quiz-game-app-3c75d',
    storageBucket: 'quiz-game-app-3c75d.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCas217mlZ6GLvtKsdezE2WmHt-R217Kco',
    appId: '1:179431012469:web:bdc479de9e6196e026e03c',
    messagingSenderId: '179431012469',
    projectId: 'quiz-game-app-3c75d',
    authDomain: 'quiz-game-app-3c75d.firebaseapp.com',
    storageBucket: 'quiz-game-app-3c75d.firebasestorage.app',
  );
}
