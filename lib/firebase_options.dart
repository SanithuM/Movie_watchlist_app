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
    apiKey: 'AIzaSyBZJtUuKwZTJJVK7fQSWKVq0mavrQ3Bbmk',
    appId: '1:448927442760:web:d236e94b736d79307a757d',
    messagingSenderId: '448927442760',
    projectId: 'cinelist-37721',
    authDomain: 'cinelist-37721.firebaseapp.com',
    storageBucket: 'cinelist-37721.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPKo8ny0H7urdlBi881VRseTDlhy2Itws',
    appId: '1:448927442760:android:26c852e0d3baf5587a757d',
    messagingSenderId: '448927442760',
    projectId: 'cinelist-37721',
    storageBucket: 'cinelist-37721.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAxdDS9w3nsrLaEGG0fsp4kM3AUWINf6E0',
    appId: '1:448927442760:ios:4539f44a5aec7c7b7a757d',
    messagingSenderId: '448927442760',
    projectId: 'cinelist-37721',
    storageBucket: 'cinelist-37721.firebasestorage.app',
    iosBundleId: 'com.example.cinelist',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAxdDS9w3nsrLaEGG0fsp4kM3AUWINf6E0',
    appId: '1:448927442760:ios:4539f44a5aec7c7b7a757d',
    messagingSenderId: '448927442760',
    projectId: 'cinelist-37721',
    storageBucket: 'cinelist-37721.firebasestorage.app',
    iosBundleId: 'com.example.cinelist',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBZJtUuKwZTJJVK7fQSWKVq0mavrQ3Bbmk',
    appId: '1:448927442760:web:802f6548fb33e3797a757d',
    messagingSenderId: '448927442760',
    projectId: 'cinelist-37721',
    authDomain: 'cinelist-37721.firebaseapp.com',
    storageBucket: 'cinelist-37721.firebasestorage.app',
  );
}
