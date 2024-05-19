// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return windows;
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
    apiKey: 'AIzaSyBWRCZKTDv-xuz2dERmoKbVoMiAel79UZE',
    appId: '1:695782239065:web:7a3c5f2e8422448c2fba48',
    messagingSenderId: '695782239065',
    projectId: 'preciomovil-83811',
    authDomain: 'preciomovil-83811.firebaseapp.com',
    storageBucket: 'preciomovil-83811.appspot.com',
    measurementId: 'G-GD0DVVDB8X',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDMJAye4VwmiPNJiUrIGcEpyKxVAR_fp5k',
    appId: '1:695782239065:android:7d737aef222d36992fba48',
    messagingSenderId: '695782239065',
    projectId: 'preciomovil-83811',
    storageBucket: 'preciomovil-83811.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCMN-DuGH7uChOb5G_aY9uXkSJFXzy7aak',
    appId: '1:695782239065:ios:e6113a92fd1c4d4f2fba48',
    messagingSenderId: '695782239065',
    projectId: 'preciomovil-83811',
    storageBucket: 'preciomovil-83811.appspot.com',
    iosBundleId: 'com.example.preciomovil',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCMN-DuGH7uChOb5G_aY9uXkSJFXzy7aak',
    appId: '1:695782239065:ios:e6113a92fd1c4d4f2fba48',
    messagingSenderId: '695782239065',
    projectId: 'preciomovil-83811',
    storageBucket: 'preciomovil-83811.appspot.com',
    iosBundleId: 'com.example.preciomovil',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBWRCZKTDv-xuz2dERmoKbVoMiAel79UZE',
    appId: '1:695782239065:web:249606647402b8712fba48',
    messagingSenderId: '695782239065',
    projectId: 'preciomovil-83811',
    authDomain: 'preciomovil-83811.firebaseapp.com',
    storageBucket: 'preciomovil-83811.appspot.com',
    measurementId: 'G-8LHXS40CV8',
  );

}