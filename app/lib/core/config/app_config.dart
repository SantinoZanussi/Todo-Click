/// Configuración de entorno de la app.
///
/// Los valores se inyectan en build/run con `--dart-define`, por ejemplo:
/// ```bash
/// flutter run --dart-define=API_BASE_URL=https://api.todoclick.com.ar \
///             --dart-define=USE_FIREBASE_EMULATOR=false
/// ```
/// Así no se hardcodean URLs por entorno ni se commitean secretos.
abstract final class AppConfig {
  /// URL base del backend Node + Express.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  /// Si la app debe apuntar a los emuladores locales de Firebase.
  static const bool useFirebaseEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: false,
  );

  /// Host de los emuladores (localhost en escritorio/web; 10.0.2.2 en Android).
  static const String emulatorHost = String.fromEnvironment(
    'EMULATOR_HOST',
    defaultValue: 'localhost',
  );

  /// `true` en builds de release.
  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  /// Habilita "Continuar con Apple" en la pantalla de login.
  ///
  /// Desactivado por defecto: Sign in with Apple requiere la capability
  /// "Sign in with Apple" (Xcode + App ID), que a su vez exige el Apple
  /// Developer Program de pago. Sin eso el botón solo mostraría un error.
  /// Cuando la cuenta y la capability estén listas, activarlo con
  /// `--dart-define=APPLE_SIGN_IN_ENABLED=true` o cambiando el default.
  static const bool appleSignInEnabled = bool.fromEnvironment(
    'APPLE_SIGN_IN_ENABLED',
    defaultValue: false,
  );
}
