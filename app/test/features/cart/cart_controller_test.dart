import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todoclick/features/auth/presentation/controllers/auth_controller.dart';
import 'package:todoclick/features/cart/domain/entities/cart.dart';
import 'package:todoclick/features/cart/domain/repositories/cart_repository.dart';
import 'package:todoclick/features/cart/presentation/controllers/cart_controller.dart';
import 'package:todoclick/features/catalog/domain/entities/product.dart';

/// Repositorio de carrito en memoria (sin SharedPreferences/Firestore).
class _FakeCartRepository implements CartRepository {
  Cart _local = Cart.empty;

  @override
  Cart readLocal() => _local;

  @override
  Future<void> saveLocal(Cart cart) async => _local = cart;

  @override
  Future<Cart> readRemote(String uid) async => Cart.empty;

  @override
  Future<void> saveRemote(String uid, Cart cart) async {}
}

Product product({String id = 'p1', double price = 1000, int stock = 5}) {
  return Product(
    id: id,
    sku: 'SKU',
    name: 'Producto',
    description: '',
    categoryId: 'c',
    subcategoryId: 's',
    brandId: 'b',
    price: price,
    stock: stock,
    dimensions: const ProductDimensions(
      weightGrams: 1,
      widthCm: 1,
      heightCm: 1,
      lengthCm: 1,
    ),
    images: const [],
    isFeatured: false,
    isOnSale: false,
    discountPercentage: 0,
    isActive: true,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );
}

ProviderContainer makeContainer() {
  final container = ProviderContainer(
    overrides: [
      cartRepositoryProvider.overrideWithValue(_FakeCartRepository()),
      // Stream que no emite → authState queda en "guest" estable (sin rebuilds).
      authStateProvider.overrideWith((ref) => const Stream.empty()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('arranca vacío', () {
    final c = makeContainer();
    expect(c.read(cartControllerProvider).isEmpty, isTrue);
  });

  test('addProduct agrega y luego suma cantidad', () {
    final c = makeContainer();
    final notifier = c.read(cartControllerProvider.notifier);
    notifier.addProduct(product());
    expect(c.read(cartControllerProvider).totalQuantity, 1);
    notifier.addProduct(product(), quantity: 2);
    expect(c.read(cartControllerProvider).totalQuantity, 3);
    expect(c.read(cartControllerProvider).distinctItems, 1);
  });

  test('setQuantity respeta el stock máximo', () {
    final c = makeContainer();
    final notifier = c.read(cartControllerProvider.notifier);
    notifier.addProduct(product(stock: 4));
    notifier.setQuantity('p1', 999);
    expect(c.read(cartControllerProvider).items.first.quantity, 4);
  });

  test('removeProduct y clear', () {
    final c = makeContainer();
    final notifier = c.read(cartControllerProvider.notifier);
    notifier.addProduct(product(id: 'a'));
    notifier.addProduct(product(id: 'b'));
    notifier.removeProduct('a');
    expect(c.read(cartControllerProvider).distinctItems, 1);
    notifier.clear();
    expect(c.read(cartControllerProvider).isEmpty, isTrue);
  });

  test('no agrega productos sin stock', () {
    final c = makeContainer();
    c.read(cartControllerProvider.notifier).addProduct(product(stock: 0));
    expect(c.read(cartControllerProvider).isEmpty, isTrue);
  });
}
