import 'package:flutter_test/flutter_test.dart';
import 'package:todoclick/features/cart/domain/entities/cart.dart';
import 'package:todoclick/features/cart/domain/entities/cart_item.dart';

CartItem item(String id, {double price = 100, int qty = 1, int maxStock = 10}) {
  return CartItem(
    productId: id,
    name: 'Item $id',
    imageUrl: null,
    unitPrice: price,
    quantity: qty,
    maxStock: maxStock,
  );
}

void main() {
  group('CartItem', () {
    test('lineTotal = precio * cantidad', () {
      expect(item('a', price: 250, qty: 3).lineTotal, 750);
    });

    test('copyWith cambia solo lo indicado', () {
      final original = item('a', qty: 1);
      final updated = original.copyWith(quantity: 4);
      expect(updated.quantity, 4);
      expect(updated.productId, original.productId);
    });
  });

  group('Cart', () {
    test('vacío por defecto', () {
      expect(const Cart().isEmpty, isTrue);
      expect(const Cart().subtotal, 0);
    });

    test('subtotal y totalQuantity', () {
      final cart = Cart(
        items: [item('a', price: 100, qty: 2), item('b', price: 50, qty: 1)],
      );
      expect(cart.subtotal, 250);
      expect(cart.totalQuantity, 3);
      expect(cart.distinctItems, 2);
    });

    test('contains', () {
      final cart = Cart(items: [item('a')]);
      expect(cart.contains('a'), isTrue);
      expect(cart.contains('z'), isFalse);
    });
  });
}
