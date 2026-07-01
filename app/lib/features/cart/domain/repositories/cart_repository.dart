import '../entities/cart.dart';

/// Persistencia del carrito.
///
/// Maneja dos backends: local (SharedPreferences, para invitados y caché) y
/// remoto (Firestore `carritos/{uid}`, para usuarios autenticados). La lógica
/// de merge al iniciar sesión vive en el controller.
abstract interface class CartRepository {
  Cart readLocal();
  Future<void> saveLocal(Cart cart);

  Future<Cart> readRemote(String uid);
  Future<void> saveRemote(String uid, Cart cart);
}
