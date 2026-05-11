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
          'DefaultFirebaseOptions: platform not supported',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBtmUKuyvmpLH9B1lGKIHRasnQym8g6K1g',
    appId: '1:813078433193:android:e89180c4193e8db6d0c8b8',
    messagingSenderId: '813078433193',
    projectId: 'medfind-115b6',
    storageBucket: 'medfind-115b6.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAgY69xjsm85Rb4eAAODXVwJYh0q56mIzM',
    appId: '1:813078433193:ios:c79ee5881824c2e8d0c8b8',
    messagingSenderId: '813078433193',
    projectId: 'medfind-115b6',
    storageBucket: 'medfind-115b6.firebasestorage.app',
    iosBundleId: 'com.medfind.mobile',
  );
}
