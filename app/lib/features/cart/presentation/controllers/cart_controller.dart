import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../data/repositories/cart_repository_impl.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>(
  (ref) => CartRepositoryImpl(
    prefs: ref.watch(sharedPreferencesProvider),
    firestore: ref.watch(firestoreProvider),
  ),
);

/// Estado y operaciones del carrito.
///
/// Para invitados persiste en local; para usuarios autenticados sincroniza con
/// Firestore. Al iniciar sesión, mergea el carrito local con el remoto.
final cartControllerProvider = NotifierProvider<CartController, Cart>(
  CartController.new,
);

class CartController extends Notifier<Cart> {
  CartRepository get _repo => ref.read(cartRepositoryProvider);

  @override
  Cart build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    final local = _repo.readLocal();
    if (user != null) {
      _mergeWithRemote(user.uid, local);
    }
    return local;
  }

  /// Agrega un producto (o incrementa su cantidad), respetando el stock.
  void addProduct(Product product, {int quantity = 1}) {
    if (!product.hasStock) return;
    final items = [...state.items];
    final index = items.indexWhere((i) => i.productId == product.id);
    if (index >= 0) {
      final current = items[index];
      final newQty = (current.quantity + quantity).clamp(1, product.stock);
      items[index] = current.copyWith(quantity: newQty);
    } else {
      items.add(
        CartItem(
          productId: product.id,
          name: product.name,
          imageUrl: product.mainImage,
          sku: product.sku,
          unitPrice: product.finalPrice,
          quantity: quantity.clamp(1, product.stock),
          maxStock: product.stock,
        ),
      );
    }
    _update(Cart(items: items));
  }

  void setQuantity(String productId, int quantity) {
    final items = [...state.items];
    final index = items.indexWhere((i) => i.productId == productId);
    if (index < 0) return;
    final item = items[index];
    final clamped = quantity.clamp(
      1,
      item.maxStock <= 0 ? quantity : item.maxStock,
    );
    items[index] = item.copyWith(quantity: clamped);
    _update(Cart(items: items));
  }

  void removeProduct(String productId) {
    _update(
      Cart(items: state.items.where((i) => i.productId != productId).toList()),
    );
  }

  void clear() => _update(Cart.empty);

  // ───────────────────────── Internos ─────────────────────────

  void _update(Cart cart) {
    state = cart;
    _persist(cart);
  }

  Future<void> _persist(Cart cart) async {
    // Leemos el usuario ANTES del await: usar `ref` después de un await puede
    // chocar con un cambio de dependencia (authState) y disparar un assert.
    final user = ref.read(authStateProvider).valueOrNull;
    await _repo.saveLocal(cart);
    if (user != null) await _repo.saveRemote(user.uid, cart);
  }

  /// Combina el carrito local con el remoto al iniciar sesión: suma cantidades
  /// de productos repetidos (acotadas por el stock conocido).
  Future<void> _mergeWithRemote(String uid, Cart local) async {
    final remote = await _repo.readRemote(uid);
    if (remote.isEmpty) {
      if (local.isNotEmpty) await _repo.saveRemote(uid, local);
      return;
    }
    final byId = {for (final i in local.items) i.productId: i};
    for (final r in remote.items) {
      final existing = byId[r.productId];
      if (existing == null) {
        byId[r.productId] = r;
      } else {
        final qty = existing.maxStock > 0
            ? (existing.quantity + r.quantity).clamp(1, existing.maxStock)
            : existing.quantity + r.quantity;
        byId[r.productId] = existing.copyWith(quantity: qty);
      }
    }
    final merged = Cart(items: byId.values.toList());
    state = merged;
    await _repo.saveLocal(merged);
    await _repo.saveRemote(uid, merged);
  }
}

/// Cantidad total de unidades en el carrito (para el badge del bottom nav).
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartControllerProvider).totalQuantity,
);
