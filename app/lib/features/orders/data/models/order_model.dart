// `cloud_firestore` exporta una clase `Order` que choca con nuestra entidad;
// la ocultamos porque acá usamos solo DocumentSnapshot/Timestamp.
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../../../core/enums/enums.dart';
import '../../../profile/domain/entities/address.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';

/// DTO de [Order]: parsea el documento de la colección `pedidos`.
class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.userId,
    required super.items,
    required super.subtotal,
    required super.discount,
    required super.shippingCost,
    required super.total,
    required super.status,
    required super.shipping,
    required super.payment,
    required super.createdAt,
    required super.updatedAt,
    super.couponCode,
    super.statusHistory,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return OrderModel(
      id: doc.id,
      orderNumber: d['orderNumber'] as String? ?? doc.id,
      userId: d['userId'] as String?,
      items: ((d['items'] as List?) ?? const [])
          .whereType<Map>()
          .map(_itemFrom)
          .toList(),
      subtotal: _d(d['subtotal']),
      discount: _d(d['discount']),
      shippingCost: _d(d['shippingCost']),
      total: _d(d['total']),
      status: OrderStatus.fromKey(d['status'] as String?),
      shipping: _shippingFrom((d['shipping'] as Map?) ?? const {}),
      payment: _paymentFrom((d['payment'] as Map?) ?? const {}),
      couponCode: d['couponCode'] as String?,
      statusHistory: ((d['statusHistory'] as List?) ?? const [])
          .whereType<Map>()
          .map(_statusChangeFrom)
          .toList(),
      createdAt: _dt(d['createdAt']),
      updatedAt: _dt(d['updatedAt']),
    );
  }

  static double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
  static int _i(Object? v) => (v as num?)?.toInt() ?? 0;
  static DateTime _dt(Object? v) =>
      v is Timestamp ? v.toDate() : DateTime.now();

  static OrderItem _itemFrom(Map m) => OrderItem(
    productId: m['productId'] as String? ?? '',
    name: m['name'] as String? ?? '',
    sku: m['sku'] as String? ?? '',
    imageUrl: m['imageUrl'] as String?,
    unitPrice: _d(m['unitPrice']),
    quantity: _i(m['quantity']),
  );

  static OrderShipping _shippingFrom(Map m) => OrderShipping(
    method: ShippingMethod.fromKey(m['method'] as String?),
    cost: _d(m['cost']),
    address: m['address'] is Map ? _addressFrom(m['address'] as Map) : null,
    branchId: m['branchId'] as String?,
    estimatedDays: (m['estimatedDays'] as num?)?.toInt(),
    trackingCode: m['trackingCode'] as String?,
    carrier: m['carrier'] as String? ?? 'Correo Argentino',
  );

  static OrderPayment _paymentFrom(Map m) => OrderPayment(
    status: PaymentStatus.fromKey(m['status'] as String?),
    preferenceId: m['preferenceId'] as String?,
    paymentId: m['paymentId'] as String?,
    method: m['method'] as String?,
    paidAt: m['paidAt'] is Timestamp
        ? (m['paidAt'] as Timestamp).toDate()
        : null,
  );

  static OrderStatusChange _statusChangeFrom(Map m) => OrderStatusChange(
    status: OrderStatus.fromKey(m['status'] as String?),
    at: _dt(m['at']),
    note: m['note'] as String?,
  );

  static Address _addressFrom(Map m) => Address(
    firstName: m['firstName'] as String? ?? '',
    lastName: m['lastName'] as String? ?? '',
    email: m['email'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    province: m['province'] as String? ?? '',
    city: m['city'] as String? ?? '',
    street: m['street'] as String? ?? '',
    apartment: m['apartment'] as String?,
    postalCode: m['postalCode'] as String? ?? '',
    notes: m['notes'] as String?,
  );
}
