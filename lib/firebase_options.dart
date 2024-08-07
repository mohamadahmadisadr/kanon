// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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
      apiKey: "AIzaSyD6dz46y3hvIdUm8cjmAJSR088sNB1rxU8",
      authDomain: "kanooniha-android.firebaseapp.com",
      projectId: "kanooniha-android",
      storageBucket: "kanooniha-android.appspot.com",
      messagingSenderId: "495671824064",
      appId: "1:495671824064:web:b4fade677302788cc56725",
      measurementId: "G-DHD483FTQ5"
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBlJGS7Ecn0GhVTwouNFmM1_XumBp1ASRc',
    appId: '1:495671824064:android:19f651d9f9075469c56725',
    messagingSenderId: '495671824064',
    projectId: 'kanooniha-android',
    storageBucket: 'kanooniha-android.appspot.com',
  );
}