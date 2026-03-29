// File này được tạo thủ công từ Firebase Console config
// Project: astraai-a400f

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:            'AIzaSyDmDps8oC6eZoE6JHkrOzF4N2GkqsinHl8',
    appId:             '1:836225855307:web:bd463d199ee984a4b582ce',
    messagingSenderId: '836225855307',
    projectId:         'astraai-a400f',
    authDomain:        'astraai-a400f.firebaseapp.com',
    storageBucket:     'astraai-a400f.firebasestorage.app',
    measurementId:     'G-M9LX0J11PZ',
  );

  // Placeholder cho Android/iOS — điền sau khi thêm app tương ứng trên Firebase Console
  static const FirebaseOptions android = FirebaseOptions(
    apiKey:            'AIzaSyDmDps8oC6eZoE6JHkrOzF4N2GkqsinHl8',
    appId:             '1:836225855307:web:bd463d199ee984a4b582ce',
    messagingSenderId: '836225855307',
    projectId:         'astraai-a400f',
    storageBucket:     'astraai-a400f.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey:            'AIzaSyDmDps8oC6eZoE6JHkrOzF4N2GkqsinHl8',
    appId:             '1:836225855307:web:bd463d199ee984a4b582ce',
    messagingSenderId: '836225855307',
    projectId:         'astraai-a400f',
    storageBucket:     'astraai-a400f.firebasestorage.app',
    iosClientId:       '',
    iosBundleId:       'com.astraai.signalsApp',
  );
}
