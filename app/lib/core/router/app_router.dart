import 'package:animations/animations.dart';
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

/// Página con transición **shared-axis horizontal** (Material motion) para las
/// rutas full-screen: al navegar "hacia adentro" la entrante entra desde la
/// derecha y la saliente se va con un fundido. Sutil y consistente en toda la
/// app. Se usa vía `pageBuilder` en cada [GoRoute] de nivel superior.
CustomTransitionPage<void> _axisPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: SharedAxisTransitionType.horizontal,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        ),
    child: child,
  );
}

/// Página con **fade-through** (cruce por el fondo). Se usa en el detalle de
/// producto para que el `Hero` de la imagen sea el protagonista del cambio
/// (la card se "expande" hacia el detalle) sin competir con un deslizamiento.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: const Duration(milliseconds: 350),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        ),
    child: child,
  );
}

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
        pageBuilder: (_, state) => _axisPage(state, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const RegisterPage()),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const ForgotPasswordPage()),
      ),

      // Catálogo: full-screen sobre el shell.
      GoRoute(
        path: AppRoutes.productList,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) {
          final args = state.extra as ProductListArgs?;
          return _axisPage(
            state,
            ProductListPage(
              args:
                  args ??
                  const ProductListArgs(
                    title: 'Productos',
                    query: ProductQuery(),
                  ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.search,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const SearchPage()),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _fadePage(
          state,
          ProductDetailPage(productId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.checkout,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const CheckoutPage()),
      ),
      GoRoute(
        path: AppRoutes.paymentResult,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(
          state,
          PaymentResultPage(orderId: state.pathParameters['orderId']!),
        ),
      ),
      GoRoute(
        path: AppRoutes.orders,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const OrdersPage()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const NotificationsPage()),
      ),
      GoRoute(
        path: AppRoutes.orderDetail,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(
          state,
          OrderDetailPage(orderId: state.pathParameters['id']!),
        ),
      ),

      // Panel de administración (full-screen, protegido por el guard de rol).
      GoRoute(
        path: AppRoutes.admin,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const AdminDashboardPage()),
      ),
      GoRoute(
        path: AppRoutes.adminProducts,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const AdminProductsPage()),
      ),
      GoRoute(
        path: AppRoutes.adminOrders,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const AdminOrdersPage()),
      ),
      GoRoute(
        path: AppRoutes.adminCategories,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) =>
            _axisPage(state, const AdminCategoriesPage()),
      ),
      GoRoute(
        path: AppRoutes.adminBrands,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const AdminBrandsPage()),
      ),
      GoRoute(
        path: AppRoutes.adminCoupons,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const AdminCouponsPage()),
      ),
      GoRoute(
        path: AppRoutes.adminPromotions,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) =>
            _axisPage(state, const AdminPromotionsPage()),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        parentNavigatorKey: _rootNavigatorKey,
        pageBuilder: (_, state) => _axisPage(state, const AdminUsersPage()),
      ),

      // Shell con bottom nav (5 ramas con estado independiente). El cambio de
      // pestaña hace un fundido cruzado suave (ver [_AnimatedBranchContainer]).
      StatefulShellRoute(
        builder: (_, _, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (_, navigationShell, children) =>
            _AnimatedBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
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

/// Contenedor de las ramas del shell (bottom nav) con **fundido cruzado** al
/// cambiar de pestaña. Mantiene todas las ramas vivas (preserva el stack de
/// cada una, igual que un `IndexedStack`), pero solo la activa es visible,
/// interactiva y "tickea" animaciones.
class _AnimatedBranchContainer extends StatelessWidget {
  const _AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        for (var i = 0; i < children.length; i++)
          AnimatedOpacity(
            opacity: i == currentIndex ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: IgnorePointer(
              ignoring: i != currentIndex,
              child: TickerMode(
                enabled: i == currentIndex,
                child: children[i],
              ),
            ),
          ),
      ],
    );
  }
}
