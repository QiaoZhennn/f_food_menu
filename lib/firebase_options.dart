import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBevfY3g5mmrmGcIBsrKwlpqmk_01CEoWY',
    appId: '1:1086117261799:web:b2ff62ab30eac5dcd04d42',
    messagingSenderId: '1086117261799',
    projectId: 'f-food-menu',
    authDomain: 'f-food-menu.firebaseapp.com',
    storageBucket: 'f-food-menu.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBvSAUjfzhNC1Oxd-fjfYvWH2VqxAK9pRI',
    appId: '1:1086117261799:android:017fb991abc36369d04d42',
    messagingSenderId: '1086117261799',
    projectId: 'f-food-menu',
    storageBucket: 'f-food-menu.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCSlBwe5l9QXy_zNK6mSDOTaLxYtJmai7o',
    appId: '1:1086117261799:ios:8ab8ba84ea977fc0d04d42',
    messagingSenderId: '1086117261799',
    projectId: 'f-food-menu',
    storageBucket: 'f-food-menu.firebasestorage.app',
    iosBundleId: 'com.example.foodMenu',
  );

}