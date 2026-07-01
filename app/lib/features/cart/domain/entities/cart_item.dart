import 'package:equatable/equatable.dart';

/// Ítem dentro del carrito.
///
/// Guarda un **snapshot** mínimo del producto (nombre, precio, imagen) además
/// de su `productId`. Así el carrito puede renderizarse sin re-fetchear cada
/// producto, y conserva el precio que el usuario vio. El precio "real" se
/// re-valida contra Firestore en el checkout (Fase 6/8) para evitar fraudes.
class CartItem extends Equatable {
  const CartItem({
    required this.productId,
    required this.name,
    required this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.maxStock,
    this.sku,
  });

  final String productId;
  final String name;
  final String? imageUrl;
  final String? sku;

  /// Precio unitario YA con descuento aplicado (snapshot al agregar).
  final double unitPrice;

  /// Cantidad seleccionada.
  final int quantity;

  /// Stock máximo disponible (para limitar el incremento de cantidad).
  final int maxStock;

  /// Subtotal de la línea.
  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({
    String? productId,
    String? name,
    String? imageUrl,
    String? sku,
    double? unitPrice,
    int? quantity,
    int? maxStock,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      sku: sku ?? this.sku,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
    );
  }

  @override
  List<Object?> get props => [
    productId,
    name,
    imageUrl,
    sku,
    unitPrice,
    quantity,
    maxStock,
  ];
}
