import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/firebase_initializer.dart';

/// Handler de mensajes FCM recibidos con la app en background/terminada.
///
/// Debe ser una función top-level con `@pragma('vm:entry-point')`. Los mensajes
/// de tipo *notification* los muestra el sistema automáticamente; acá solo
/// dejamos el gancho para procesamiento adicional si hiciera falta.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op por ahora.
}

/// Inicialización previa a `runApp`.
///
/// Realiza el trabajo asíncrono necesario para arrancar la app y devuelve las
/// dependencias que se inyectan en el `ProviderScope` (por ahora,
/// `SharedPreferences`).
///
/// La inicialización de Firebase se hace con `try/catch`: si todavía no
/// completaste el setup de la Fase 2 (firebase_options.dart con valores
/// reales), la app igual arranca para poder ver la UI; solo fallarán las
/// funciones que dependan de Firebase.
Future<BootstrapResult> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Datos de localización para formateo de fechas en es_AR.
  await initializeDateFormatting('es_AR');

  // Firebase (tolerante a fallos en desarrollo).
  var firebaseReady = false;
  try {
    await FirebaseInitializer.ensureInitialized();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    firebaseReady = true;
  } catch (e) {
    debugPrint(
      '⚠️ Firebase no se pudo inicializar (¿completaste la Fase 2?): $e',
    );
  }

  final prefs = await SharedPreferences.getInstance();

  return BootstrapResult(prefs: prefs, firebaseReady: firebaseReady);
}

/// Resultado del bootstrap con las dependencias listas para inyectar.
class BootstrapResult {
  const BootstrapResult({required this.prefs, required this.firebaseReady});

  final SharedPreferences prefs;
  final bool firebaseReady;
}
