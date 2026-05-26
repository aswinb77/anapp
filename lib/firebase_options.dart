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
    apiKey: 'AIzaSyCp_AVtOe8OC2PgYy-lC2MNE45Do1MNv3Q',
    appId: '1:124101866626:web:824f06be58dbb65ce5b09b',
    messagingSenderId: '124101866626',
    projectId: 'movie-2e707',
    authDomain: 'movie-2e707.firebaseapp.com',
    storageBucket: 'movie-2e707.firebasestorage.app',
    measurementId: 'G-M0YRBRF2QL',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDCwyqiCkR9PAFn7AcRX0wvuvnnkLPxi_s',
    appId: '1:124101866626:android:e032092bcd630395e5b09b',
    messagingSenderId: '124101866626',
    projectId: 'movie-2e707',
    storageBucket: 'movie-2e707.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBU_DNsr7K8U177aqvZ3dMS5-1n2mDLRgo',
    appId: '1:124101866626:ios:YOUR_APP_ID',
    messagingSenderId: '124101866626',
    projectId: 'movie-2e707',
    storageBucket: 'movie-2e707.appspot.com',
    iosBundleId: 'com.example.moviecc',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBU_DNsr7K8U177aqvZ3dMS5-1n2mDLRgo',
    appId: '1:124101866626:ios:YOUR_APP_ID',
    messagingSenderId: '124101866626',
    projectId: 'movie-2e707',
    storageBucket: 'movie-2e707.appspot.com',
    iosBundleId: 'com.example.moviecc',
  );
}