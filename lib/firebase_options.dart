import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) throw UnsupportedError('Web not configured.');
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2fsBnxDnwYTmDWFDSNV6WKS278m_lyQE',
    appId: '1:340096103166:android:0e9151830a73cf22fbebaf',
    messagingSenderId: '340096103166',
    projectId: 'teetime-main',
    storageBucket: 'teetime-main.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD9qpVoecA0DQzfoeVKSiBD2VPz4xa_frk',
    appId: '1:340096103166:ios:80a93e01bfdb8971fbebaf',
    messagingSenderId: '340096103166',
    projectId: 'teetime-main',
    storageBucket: 'teetime-main.firebasestorage.app',
    iosClientId: '340096103166-mr9aa7aonb7g9adcnd3ievids77685f6.apps.googleusercontent.com',
    iosBundleId: 'com.teetime.golf',
  );
}
