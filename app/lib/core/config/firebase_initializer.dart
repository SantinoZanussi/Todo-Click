import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

/// Inicializa Firebase para la app.
///
/// Se invoca una sola vez al arrancar, antes de `runApp` (el cableado real en
/// `main.dart` se completa en la Fase 3, junto con el `ProviderScope` de
/// Riverpod). Encapsular la inicialización acá la hace testeable y evita
/// repetir las opciones por plataforma.
abstract final class FirebaseInitializer {
  static bool _initialized = false;

  /// Garantiza que Firebase esté inicializado (idempotente).
  static Future<void> ensureInitialized() async {
    if (_initialized || Firebase.apps.isNotEmpty) {
      _initialized = true;
      return;
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _initialized = true;
  }
}
