import '../../../../core/enums/enums.dart';

/// Resultado de crear el checkout: id del pedido + URL de Checkout Pro.
class CheckoutResult {
  const CheckoutResult({
    required this.orderId,
    required this.orderNumber,
    required this.preferenceId,
    required this.initPoint,
  });

  final String orderId;
  final String orderNumber;
  final String preferenceId;

  /// URL de Mercado Pago Checkout Pro a abrir.
  final String initPoint;

  factory CheckoutResult.fromJson(Map<String, dynamic> j) => CheckoutResult(
    orderId: j['orderId'] as String? ?? '',
    orderNumber: j['orderNumber'] as String? ?? '',
    preferenceId: j['preferenceId'] as String? ?? '',
    initPoint: j['initPoint'] as String? ?? '',
  );
}

/// Estado de un pedido consultado al backend tras volver del checkout.
class OrderStatusResult {
  const OrderStatusResult({
    required this.orderId,
    required this.orderNumber,
    required this.status,
    required this.paymentStatus,
    required this.total,
  });

  final String orderId;
  final String orderNumber;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final double total;

  bool get isApproved => paymentStatus == PaymentStatus.approved;
  bool get isRejected =>
      paymentStatus == PaymentStatus.rejected ||
      paymentStatus == PaymentStatus.cancelled;

  factory OrderStatusResult.fromJson(Map<String, dynamic> j) =>
      OrderStatusResult(
        orderId: j['orderId'] as String? ?? '',
        orderNumber: j['orderNumber'] as String? ?? '',
        status: OrderStatus.fromKey(j['status'] as String?),
        paymentStatus: PaymentStatus.fromKey(j['paymentStatus'] as String?),
        total: (j['total'] as num?)?.toDouble() ?? 0,
      );
}
