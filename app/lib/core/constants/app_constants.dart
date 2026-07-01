/// Constantes globales de la aplicación.
///
/// Valores que NO son secretos y que son estables a través de entornos.
/// Las claves/URLs sensibles van en variables de entorno (`--dart-define`)
/// y se exponen mediante `core/config/app_config.dart` (Fase 3), nunca acá.
abstract final class AppConstants {
  // Identidad de la app
  static const String appName = 'TodoClick';
  static const String appTagline = 'Todo lo que buscás, a un click';
  static const String supportEmail = 'soporte@todoclick.com.ar';

  // Localización / negocio
  static const String defaultLocale = 'es_AR';
  static const String currencyCode = 'ARS';
  static const String currencySymbol = '\$';
  static const String countryCode = 'AR';

  // Paginación
  static const int productsPageSize = 20;
  static const int ordersPageSize = 15;

  // Reglas de negocio
  static const int maxCartItemQuantity = 99;
  static const int maxProductImages = 8;

  // Tiempos
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration debounceSearch = Duration(milliseconds: 350);
}

/// Nombres de colecciones de Firestore en un único lugar.
///
/// Centralizar los nombres evita typos y facilita un eventual rename.
abstract final class FirestoreCollections {
  static const String users = 'usuarios';
  static const String products = 'productos';
  static const String categories = 'categorias';
  static const String brands = 'marcas';
  static const String orders = 'pedidos';
  static const String favorites = 'favoritos';
  static const String carts = 'carritos';
  static const String coupons = 'cupones';
  static const String promotions = 'promociones';
  static const String notifications = 'notificaciones';
  static const String config = 'configuracion';
}

/// Claves de almacenamiento local (SharedPreferences / Hive).
abstract final class StorageKeys {
  static const String guestCart = 'guest_cart_v1';
  static const String themeMode = 'theme_mode';
  static const String onboardingSeen = 'onboarding_seen';
  static const String fcmToken = 'fcm_token';
}
