import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/app_providers.dart';
import '../../../../core/enums/enums.dart';
import '../../../catalog/data/models/product_model.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../promotions/data/models/coupon_model.dart';
import '../../../promotions/data/models/promotion_model.dart';
import '../../../promotions/domain/entities/coupon.dart';
import '../../../promotions/domain/entities/promotion.dart';
import '../../data/admin_api.dart';
import '../../domain/entities/admin_views.dart';
import '../../domain/entities/dashboard_stats.dart';

/// Cliente del API admin (usa el Dio autenticado con el token de Firebase).
final adminApiProvider = Provider<AdminApi>(
  (ref) => AdminApi(ref.watch(dioProvider)),
);

/// Estadísticas del dashboard.
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final json = await ref.watch(adminApiProvider).getStats();
  return DashboardStats.fromJson(json);
});

/// Todos los productos (incluye inactivos) para el admin.
final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  final snap = await ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.products)
      .orderBy('createdAt', descending: true)
      .limit(300)
      .get();
  return snap.docs.map(ProductModel.fromFirestore).cast<Product>().toList();
});

/// Pedidos para el admin, opcionalmente filtrados por estado.
final adminOrdersProvider =
    FutureProvider.family<List<AdminOrderSummary>, OrderStatus?>((
      ref,
      status,
    ) async {
      var query = ref
          .watch(firestoreProvider)
          .collection(FirestoreCollections.orders)
          .orderBy('createdAt', descending: true)
          .limit(100);
      if (status != null) {
        query = ref
            .watch(firestoreProvider)
            .collection(FirestoreCollections.orders)
            .where('status', isEqualTo: status.key)
            .orderBy('createdAt', descending: true)
            .limit(100);
      }
      final snap = await query.get();
      return snap.docs.map(AdminOrderSummary.fromFirestore).toList();
    });

/// Usuarios registrados.
final adminUsersProvider = FutureProvider<List<AdminUserView>>((ref) async {
  final snap = await ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.users)
      .limit(300)
      .get();
  return snap.docs.map(AdminUserView.fromFirestore).toList();
});

/// Cupones (solo admin puede leerlos).
final adminCouponsProvider = FutureProvider<List<Coupon>>((ref) async {
  final snap = await ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.coupons)
      .limit(200)
      .get();
  return snap.docs.map(CouponModel.fromFirestore).cast<Coupon>().toList();
});

/// Promociones.
final adminPromotionsProvider = FutureProvider<List<Promotion>>((ref) async {
  final snap = await ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.promotions)
      .limit(200)
      .get();
  return snap.docs.map(PromotionModel.fromFirestore).cast<Promotion>().toList();
});
