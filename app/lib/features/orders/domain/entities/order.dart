import 'package:equatable/equatable.dart';

import '../../../../core/enums/enums.dart';
import '../../../profile/domain/entities/address.dart';
import 'order_item.dart';

/// Información de envío asociada a un pedido.
class OrderShipping extends Equatable {
  const OrderShipping({
    required this.method,
    required this.cost,
    this.address,
    this.branchId,
    this.estimatedDays,
    this.trackingCode,
    this.carrier = 'Correo Argentino',
  });

  final ShippingMethod method;

  /// Costo del envío en ARS (0 para retiro en tienda).
  final double cost;

  /// Dirección de entrega (para envío a domicilio).
  final Address? address;

  /// Id de la sucursal de correo (para retiro en sucursal).
  final String? branchId;

  /// Tiempo estimado de entrega en días hábiles.
  final int? estimatedDays;

  /// Código de seguimiento del envío (provisto por el proveedor de logística).
  final String? trackingCode;

  final String carrier;

  @override
  List<Object?> get props => [
    method,
    cost,
    address,
    branchId,
    estimatedDays,
    trackingCode,
    carrier,
  ];
}

/// Datos del pago asociados a un pedido (referencia a Mercado Pago).
class OrderPayment extends Equatable {
  const OrderPayment({
    required this.status,
    this.preferenceId,
    this.paymentId,
    this.method,
    this.paidAt,
  });

  final PaymentStatus status;

  /// Id de la preferencia de Mercado Pago (Checkout Pro).
  final String? preferenceId;

  /// Id del pago confirmado (llega por webhook).
  final String? paymentId;

  /// Medio de pago usado (tarjeta, dinero en cuenta, etc.).
  final String? method;

  final DateTime? paidAt;

  @override
  List<Object?> get props => [status, preferenceId, paymentId, method, paidAt];
}

/// Pedido / orden de compra.
///
/// Documento de la colección `pedidos`. Es el agregado central del checkout:
/// reúne ítems, totales, envío, pago y estado. El `userId` es `null` para
/// compras de invitado (en ese caso el contacto vive en `shipping.address`).
class Order extends Equatable {
  const Order({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.shippingCost,
    required this.total,
    required this.status,
    required this.shipping,
    required this.payment,
    required this.createdAt,
    required this.updatedAt,
    this.couponCode,
    this.statusHistory = const [],
  });

  final String id;

  /// Número de pedido legible para el cliente (p. ej. `TC-2026-000123`).
  final String orderNumber;

  /// `null` si la compra fue como invitado.
  final String? userId;

  final List<OrderItem> items;

  /// Subtotal de productos (suma de líneas).
  final double subtotal;

  /// Descuento total aplicado (cupones + promociones).
  final double discount;

  final double shippingCost;

  /// Total final = subtotal - discount + shippingCost.
  final double total;

  final OrderStatus status;
  final OrderShipping shipping;
  final OrderPayment payment;

  /// Cupón aplicado, si hubo.
  final String? couponCode;

  /// Historial de cambios de estado (para la línea de tiempo del pedido).
  final List<OrderStatusChange> statusHistory;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isGuestOrder => userId == null;
  int get totalQuantity => items.fold(0, (sum, i) => sum + i.quantity);

  Order copyWith({
    OrderStatus? status,
    OrderShipping? shipping,
    OrderPayment? payment,
    List<OrderStatusChange>? statusHistory,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id,
      orderNumber: orderNumber,
      userId: userId,
      items: items,
      subtotal: subtotal,
      discount: discount,
      shippingCost: shippingCost,
      total: total,
      status: status ?? this.status,
      shipping: shipping ?? this.shipping,
      payment: payment ?? this.payment,
      couponCode: couponCode,
      statusHistory: statusHistory ?? this.statusHistory,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    userId,
    items,
    subtotal,
    discount,
    shippingCost,
    total,
    status,
    shipping,
    payment,
    couponCode,
    statusHistory,
    createdAt,
    updatedAt,
  ];
}

/// Una transición de estado registrada en el historial del pedido.
class OrderStatusChange extends Equatable {
  const OrderStatusChange({required this.status, required this.at, this.note});

  final OrderStatus status;
  final DateTime at;
  final String? note;

  @override
  List<Object?> get props => [status, at, note];
}
