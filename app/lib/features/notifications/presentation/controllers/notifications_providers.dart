import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/app_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/app_notification.dart';

/// Notificaciones del usuario autenticado (stream en tiempo real).
final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(const []);

  return ref
      .watch(firestoreProvider)
      .collection(FirestoreCollections.notifications)
      .where('userId', isEqualTo: user.uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs.map(AppNotification.fromFirestore).toList());
});

/// Cantidad de notificaciones sin leer (para el badge).
final unreadNotificationsProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).valueOrNull ?? const [];
  return list.where((n) => !n.read).length;
});

/// Marca notificaciones como leídas (el cliente solo puede tocar `read`/`readAt`).
final notificationsActionsProvider = Provider<NotificationsActions>(
  (ref) => NotificationsActions(ref.watch(firestoreProvider)),
);

class NotificationsActions {
  const NotificationsActions(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestoreCollections.notifications);

  Future<void> markAsRead(String id) => _col.doc(id).update({
    'read': true,
    'readAt': FieldValue.serverTimestamp(),
  });

  Future<void> markAllAsRead(Iterable<String> ids) async {
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.update(_col.doc(id), {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }
}
