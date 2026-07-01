import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/admin/presentation/pages/admin_brands_page.dart';
import '../../features/admin/presentation/pages/admin_categories_page.dart';
import '../../features/admin/presentation/pages/admin_coupons_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/admin_orders_page.dart';
import '../../features/admin/presentation/pages/admin_products_page.dart';
import '../../features/admin/presentation/pages/admin_promotions_page.dart';
import '../../features/admin/presentation/pages/admin_users_page.dart';
import '../../features/auth/domain/entities/app_user.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/catalog/domain/entities/product_query.dart';
import '../../features/checkout/presentation/pages/checkout_page.dart';
import '../../features/checkout/presentation/pages/payment_result_page.dart';
import '../../features/catalog/presentation/pages/categories_page.dart';
import '../../features/catalog/presentation/pages/home_page.dart';
import '../../features/catalog/presentation/pages/product_detail_page.dart';
import '../../features/catalog/presentation/pages/product_list_page.dart';
import '../../features/catalog/presentation/pages/search_page.dart';
import '../../features/catalog/presentation/widgets/product_list_args.dart';
import '../../features/favorites/presentation/pages/favorites_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/orders/presentation/pages/order_detail_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../presentation/app_shell.dart';
import 'app_routes.dart';

// Navigator keys: uno raíz (para rutas full-screen como login/checkout) y uno
// por rama del shell (cada pestaña preserva su propio stack).
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _homeNavigatorKey = GlobalKey<NavigatorState>();
final _categoriesNavigatorKey = GlobalKey<NavigatorState>();
final _cartNavigatorKey = GlobalKey<NavigatorState>();
final _favoritesNavigatorKey = GlobalKey<NavigatorState>();
final _profileNavigatorKey = GlobalKey<NavigatorState>();

/// Provider del router de la app.
///
/// Observa [authStateProvider] mediante un `refreshListenable` para re-evaluar
/// el `redirect` cuando cambia la sesión (auth gate). Navegar el catálogo NO
/// requiere sesión (modo invitado); solo se evita que un usuario logueado
/// vuelva a las pantallas de login/registro.
final routerProvider = Provider<GoRouter>((ref) {
  // Listenable que dispara el refresh del router al cambiar el estado de auth.
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  const authRoutes = {
    AppRoutes.login,
    AppRoutes.register,
    AppRoutes.forgotPassword,
  };

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refresh,
    redirect: (context, state) {
      final AppUser? user = ref.read(authStateProvider).valueOrNull;
      final isLoggedIn = user != null;
      final location = state.matchedLocation;

      // Si ya inició sesión y está en una pantalla de auth → al inicio.
      if (isLoggedIn && authRoutes.contains(location)) {
        return AppRoutes.home;
      }
      // Guard del panel admin: solo accesible con rol admin.
      if (location.startsWith(AppRoutes.admin) && !(user?.isAdmin ?? false)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(
        path: AppRoutes.login,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const RegisterPage(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const ForgotPasswordPage(),
      ),

      // Catálogo: full-screen sobre el shell.
      GoRoute(
        path: AppRoutes.productList,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final args = state.extra as ProductListArgs?;
          return ProductListPage(
            args:
                args ??
                const ProductListArgs(
                  title: 'Productos',
                  query: ProductQuery(),
                ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const SearchPage(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            ProductDetailPage(productId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const CheckoutPage(),
      ),
      GoRoute(
        path: AppRoutes.paymentResult,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            PaymentResultPage(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.orders,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const OrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const NotificationsPage(),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            OrderDetailPage(orderId: state.pathParameters['id']!),
      ),

      // Panel de administración (full-screen, protegido por el guard de rol).
      GoRoute(
        path: AppRoutes.admin,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.adminProducts,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminProductsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminOrders,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminOrdersPage(),
      ),
      GoRoute(
        path: AppRoutes.adminCategories,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminCategoriesPage(),
      ),
      GoRoute(
        path: AppRoutes.adminBrands,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminBrandsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminCoupons,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminCouponsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminPromotions,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminPromotionsPage(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, _) => const AdminUsersPage(),
      ),

      // Shell con bottom nav (5 ramas con estado independiente).
      StatefulShellRoute.indexedStack(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (_, _) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _categoriesNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.categories,
                builder: (_, _) => const CategoriesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _cartNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (_, _) => const CartPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _favoritesNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.favorites,
                builder: (_, _) => const FavoritesPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (_, _) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text('Ruta no encontrada: ${state.uri}'))),
  );
});
