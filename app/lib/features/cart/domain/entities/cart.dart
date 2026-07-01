import 'package:equatable/equatable.dart';

import 'cart_item.dart';

/// Carrito de compras.
///
/// Para invitados vive en almacenamiento local; para usuarios autenticados se
/// sincroniza con `carritos/{uid}` en Firestore. Al iniciar sesión, el
/// carrito local se *mergea* con el remoto (Fase 6).
///
/// El carrito solo conoce sus ítems y subtotales de productos. Los costos de
/// envío y los descuentos por cupón se resuelven en el checkout, no acá, para
/// mantener una única fuente de verdad de esos cálculos.
class Cart extends Equatable {
  const Cart({this.items = const []});

  final List<CartItem> items;

  /// Carrito vacío (estado inicial).
  static const Cart empty = Cart();

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Cantidad total de unidades (suma de cantidades de cada ítem).
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  /// Cantidad de líneas distintas en el carrito.
  int get distinctItems => items.length;

  /// Subtotal de productos (sin envío ni cupones).
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  /// `true` si el producto ya está en el carrito.
  bool contains(String productId) =>
      items.any((item) => item.productId == productId);

  Cart copyWith({List<CartItem>? items}) => Cart(items: items ?? this.items);

  @override
  List<Object?> get props => [items];
}
