import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REDACTED',
    appId: '1:124101866626:web:824f06be58dbb65ce5b09b',
    messagingSenderId: '124101866626',
    projectId: 'movie-2e707',
    authDomain: 'movie-2e707.firebaseapp.com',
    storageBucket: 'movie-2e707.firebasestorage.app',
    measurementId: 'G-M0YRBRF2QL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REDACTED',
    appId: '1:124101866626:android:e032092bcd630395e5b09b',
    messagingSenderId: '124101866626',
    projectId: 'movie-2e707',
    storageBucket: 'movie-2e707.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:dummy-app-id:ios:dummy',
    messagingSenderId: 'dummy-sender-id',
    projectId: 'dummy-project-id',
    storageBucket: 'dummy-project-id.appspot.com',
    iosBundleId: 'com.example.moviecc',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:dummy-app-id:ios:dummy',
    messagingSenderId: 'dummy-sender-id',
    projectId: 'dummy-project-id',
    storageBucket: 'dummy-project-id.appspot.com',
    iosBundleId: 'com.example.moviecc',
  );
}