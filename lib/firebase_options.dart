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
    apiKey: 'AIzaSyDEMOKEYFORLOCALDEVANDTESTING1234567',
    appId: '1:123456789012:android:abcdef0123456789',
    messagingSenderId: '123456789012',
    projectId: 'quiz-game-app-demo',
    storageBucket: 'quiz-game-app-demo.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDEMOKEYFORLOCALDEVANDTESTING1234567',
    appId: '1:123456789012:web:abcdef0123456789',
    messagingSenderId: '123456789012',
    projectId: 'quiz-game-app-demo',
    authDomain: 'quiz-game-app-demo.firebaseapp.com',
    storageBucket: 'quiz-game-app-demo.appspot.com',
  );
}
