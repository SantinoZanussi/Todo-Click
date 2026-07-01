// ⚠️ ARCHIVO PLANTILLA — REEMPLAZAR CON EL GENERADO POR FLUTTERFIRE ⚠️
//
// Este archivo normalmente lo GENERA automáticamente la CLI de FlutterFire con
// los valores reales de tu proyecto Firebase. Mientras tanto, dejamos esta
// plantilla con placeholders para que el código compile y quede documentada
// la estructura esperada.
//
// Para generarlo de verdad (Fase 2 — requiere tu cuenta de Google):
//   1. dart pub global activate flutterfire_cli
//   2. cd app
//   3. flutterfire configure --project=<tu-project-id> \
//        --platforms=android,ios,web
//
// Eso sobrescribe este archivo y agrega google-services.json (Android) y
// GoogleService-Info.plist (iOS). Ver docs/FIREBASE_SETUP.md.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Opciones de Firebase por plataforma.
class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

  /// Devuelve las opciones correspondientes a la plataforma actual.
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'TodoClick v1 solo soporta Android, iOS y Web. '
          'Plataforma no soportada: $defaultTargetPlatform',
        );
    }
  }

  // TODO(Fase 2): reemplazar TODOS los valores 'REEMPLAZAR_*' con los reales
  // (los provee flutterfire configure). No commitear claves de producción si
  // el repo fuera público (las API keys de Firebase web son públicas por
  // diseño, pero igual conviene restringirlas por dominio en la consola).

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDHQCeVIp_M2Ps8JC-fgdoPd84fUbVUJxs',
    appId: '1:203173641627:web:5ce146ae8b70e19888753e',
    messagingSenderId: '203173641627',
    projectId: 'todo-click-4aa1e',
    authDomain: 'todo-click-4aa1e.firebaseapp.com',
    storageBucket: 'todo-click-4aa1e.firebasestorage.app',
    measurementId: 'G-EWXM2CZ92Z',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCEFj635j_bCAvFYxDlFI8cc49F4lB_-h8',
    appId: '1:203173641627:android:3ff9e7ab772d34fe88753e',
    messagingSenderId: '203173641627',
    projectId: 'todo-click-4aa1e',
    storageBucket: 'todo-click-4aa1e.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAk4SlwLIt1F_XWY12078V1rsI0RALEiLw',
    appId: '1:203173641627:ios:d7fe66c1a15d14c388753e',
    messagingSenderId: '203173641627',
    projectId: 'todo-click-4aa1e',
    storageBucket: 'todo-click-4aa1e.firebasestorage.app',
    iosClientId:
        '203173641627-tv425oq2pn59hv5uv4p1nq31b50382d9.apps.googleusercontent.com',
    iosBundleId: 'com.example.todoclick',
  );
}
