import '../../domain/entities/cart_item.dart';

/// DTO de [CartItem] para (de)serializar el carrito tanto en almacenamiento
/// local (JSON en SharedPreferences) como en Firestore (`carritos/{uid}`).
class CartItemModel extends CartItem {
  const CartItemModel({
    required super.productId,
    required super.name,
    required super.imageUrl,
    required super.unitPrice,
    required super.quantity,
    required super.maxStock,
    super.sku,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> m) => CartItemModel(
    productId: m['productId'] as String? ?? '',
    name: m['name'] as String? ?? '',
    imageUrl: m['imageUrl'] as String?,
    sku: m['sku'] as String?,
    unitPrice: (m['unitPrice'] as num?)?.toDouble() ?? 0,
    quantity: (m['quantity'] as num?)?.toInt() ?? 1,
    maxStock: (m['maxStock'] as num?)?.toInt() ?? 0,
  );

  factory CartItemModel.fromEntity(CartItem i) => CartItemModel(
    productId: i.productId,
    name: i.name,
    imageUrl: i.imageUrl,
    sku: i.sku,
    unitPrice: i.unitPrice,
    quantity: i.quantity,
    maxStock: i.maxStock,
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'name': name,
    'imageUrl': imageUrl,
    'sku': sku,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'maxStock': maxStock,
  };
}
