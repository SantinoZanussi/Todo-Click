import 'package:equatable/equatable.dart';

/// Línea de un pedido (snapshot inmutable del producto al momento de comprar).
///
/// A diferencia de [CartItem], esto se congela cuando se confirma el pedido:
/// aunque luego cambie el precio o el nombre del producto, el pedido conserva
/// los valores históricos. Es la fuente de verdad para facturación.
class OrderItem extends Equatable {
  const OrderItem({
    required this.productId,
    required this.name,
    required this.sku,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
  });

  final String productId;
  final String name;
  final String sku;
  final String? imageUrl;

  /// Precio unitario cobrado (con descuento ya aplicado).
  final double unitPrice;
  final int quantity;

  double get lineTotal => unitPrice * quantity;

  @override
  List<Object?> get props => [
    productId,
    name,
    sku,
    imageUrl,
    unitPrice,
    quantity,
  ];
}
