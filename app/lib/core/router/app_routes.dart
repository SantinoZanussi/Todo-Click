/// Rutas de la app centralizadas (evita strings mágicos en la navegación).
abstract final class AppRoutes {
  // Arranque
  static const String splash = '/splash';

  // Pestañas principales (dentro del shell con bottom nav)
  static const String home = '/home';
  static const String categories = '/categories';
  static const String cart = '/cart';
  static const String favorites = '/favorites';
  static const String profile = '/profile';

  // Notificaciones (Fase 10)
  static const String notifications = '/notifications';

  // Autenticación (Fase 4)
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Catálogo (Fase 5)
  static const String productList = '/products';
  static const String search = '/search';
  static const String productDetail = '/product/:id';
  static String productDetailOf(String id) => '/product/$id';

  // Checkout / pedidos (Fases 6, 8)
  static const String checkout = '/checkout';
  static const String paymentResult = '/payment/:orderId';
  static String paymentResultOf(String orderId) => '/payment/$orderId';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static String orderDetailOf(String id) => '/orders/$id';

  // Panel admin (Fase 7)
  static const String admin = '/admin';
  static const String adminProducts = '/admin/products';
  static const String adminOrders = '/admin/orders';
  static const String adminCategories = '/admin/categories';
  static const String adminBrands = '/admin/brands';
  static const String adminCoupons = '/admin/coupons';
  static const String adminPromotions = '/admin/promotions';
  static const String adminUsers = '/admin/users';
}
