/// Contrato de persistencia remota de favoritos (Firestore `favoritos/{uid}`).
///
/// El manejo local (invitados) y la sincronización viven en el controller; este
/// repositorio solo cubre la parte remota.
abstract interface class FavoritesRepository {
  Future<Set<String>> getFavorites(String uid);
  Future<void> setFavorites(String uid, Set<String> productIds);
}
