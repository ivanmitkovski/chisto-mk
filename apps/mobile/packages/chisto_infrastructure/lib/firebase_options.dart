// File generated from Firebase console config (project: chisto-mk-dev).
// Regenerate with: flutterfire configure
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA4uto9B_sd6n7UTw2V1FnHE2YfIMFdoA8',
    appId: '1:119940261782:android:95b0b9545a1d54acc75fb7',
    messagingSenderId: '119940261782',
    projectId: 'chisto-mk-dev',
    storageBucket: 'chisto-mk-dev.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD50etWzraDnre1ygvKOOQXQK7FF_0pnq8',
    appId: '1:119940261782:ios:6a268bcb1b828e43c75fb7',
    messagingSenderId: '119940261782',
    projectId: 'chisto-mk-dev',
    storageBucket: 'chisto-mk-dev.firebasestorage.app',
    iosBundleId: 'mk.chisto.chistoMobile',
  );
}
