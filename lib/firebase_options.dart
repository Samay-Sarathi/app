// ============================================================================
// GENERATED FILE — Run `flutterfire configure` to regenerate.
//
// This is a placeholder. To set up Firebase for your project:
//   1. Run `firebase login` (if not already authenticated)
//   2. Run `flutterfire configure` in the app directory
//   3. This file will be overwritten with your project's configuration
//
// The generated file provides DefaultFirebaseOptions used in main.dart.
// ============================================================================

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions is not configured for ${defaultTargetPlatform.name}. '
          'Run `flutterfire configure` to generate proper configuration.',
        );
    }
  }

  // TODO: Replace with real values from `flutterfire configure`
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'PLACEHOLDER',
    storageBucket: 'PLACEHOLDER',
  );

  // TODO: Replace with real values from `flutterfire configure`
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER',
    appId: 'PLACEHOLDER',
    messagingSenderId: 'PLACEHOLDER',
    projectId: 'PLACEHOLDER',
    storageBucket: 'PLACEHOLDER',
    iosBundleId: 'com.example.lifeline',
  );
}
