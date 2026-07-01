import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/app_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/order_model.dart';
import '../../domain/entities/order.dart';

/// Pedidos del usuario autenticado (stream en tiempo real desde Firestore).
///
/// Para invitados emite lista vacía (sus pedidos no son legibles por reglas;
/// el seguimiento se hace con el número de pedido / estado vía backend).
final userOrdersProvider = StreamProvider<List<Order>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);

  return ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.orders)
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snap) =>
            snap.docs.map(OrderModel.fromFirestore).cast<Order>().toList(),
      );
});

/// Detalle de un pedido por id (para usuarios autenticados).
final orderByIdProvider = StreamProvider.family<Order?, String>((ref, id) {
  return ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.orders)
      .doc(id)
      .snapshots()
      .map((doc) => doc.exists ? OrderModel.fromFirestore(doc) : null);
});
