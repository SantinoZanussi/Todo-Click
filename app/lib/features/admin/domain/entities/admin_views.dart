import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/enums.dart';

/// Vista resumida de un pedido para el listado del panel admin.
class AdminOrderSummary {
  const AdminOrderSummary({
    required this.id,
    required this.orderNumber,
    required this.total,
    required this.status,
    required this.createdAt,
    required this.customerName,
    required this.customerEmail,
    required this.itemCount,
    this.userId,
  });

  final String id;
  final String orderNumber;
  final double total;
  final OrderStatus status;
  final DateTime createdAt;
  final String customerName;
  final String customerEmail;
  final int itemCount;
  final String? userId;

  factory AdminOrderSummary.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    final shipping = (d['shipping'] as Map?) ?? const {};
    final address = (shipping['address'] as Map?) ?? const {};
    final items = (d['items'] as List?) ?? const [];
    final created = d['createdAt'];
    return AdminOrderSummary(
      id: doc.id,
      orderNumber: d['orderNumber'] as String? ?? doc.id,
      total: (d['total'] as num?)?.toDouble() ?? 0,
      status: OrderStatus.fromKey(d['status'] as String?),
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
      customerName: address['firstName'] != null
          ? '${address['firstName']} ${address['lastName'] ?? ''}'.trim()
          : 'Cliente',
      customerEmail: address['email'] as String? ?? '',
      itemCount: items.length,
      userId: d['userId'] as String?,
    );
  }
}

/// Vista de usuario para el listado del panel admin.
class AdminUserView {
  const AdminUserView({
    required this.uid,
    required this.email,
    required this.role,
    this.displayName,
    this.createdAt,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String? displayName;
  final DateTime? createdAt;

  bool get isAdmin => role.isAdmin;

  factory AdminUserView.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    final created = d['createdAt'];
    return AdminUserView(
      uid: doc.id,
      email: d['email'] as String? ?? '',
      role: UserRole.fromKey(d['role'] as String?),
      displayName: d['displayName'] as String?,
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
