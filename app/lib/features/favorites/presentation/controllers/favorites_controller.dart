import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../catalog/domain/entities/product.dart';
import '../../../catalog/presentation/controllers/catalog_providers.dart';
import '../../data/repositories/favorites_repository_impl.dart';
import '../../domain/repositories/favorites_repository.dart';

const _kFavoritesKey = 'favorites_v1';

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepositoryImpl(ref.watch(firestoreProvider)),
);

/// Controla el conjunto de IDs de productos favoritos.
///
/// Estrategia híbrida:
///  • **Invitado:** se persiste en `SharedPreferences` (instantáneo, offline).
///  • **Logueado:** además se sincroniza con `favoritos/{uid}` en Firestore.
///  • Al iniciar sesión, los favoritos locales se **mergean** con los remotos.
final favoritesControllerProvider =
    NotifierProvider<FavoritesController, Set<String>>(FavoritesController.new);

class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final user = ref.watch(authStateProvider).valueOrNull;
    final prefs = ref.read(sharedPreferencesProvider);
    final local = prefs.getStringList(_kFavoritesKey)?.toSet() ?? <String>{};

    // Si hay sesión, mergeamos con lo remoto (fire-and-forget).
    if (user != null) {
      _mergeWithRemote(user.uid, local);
    }
    return local;
  }

  bool isFavorite(String productId) => state.contains(productId);

  /// Agrega o quita un producto de favoritos.
  Future<void> toggle(String productId) async {
    final next = {...state};
    if (!next.add(productId)) next.remove(productId);
    state = next;
    await _persist(next);
  }

  Future<void> _mergeWithRemote(String uid, Set<String> local) async {
    final repo = ref.read(favoritesRepositoryProvider);
    final remote = await repo.getFavorites(uid);
    final merged = {...local, ...remote};
    if (merged.length != state.length || !merged.containsAll(state)) {
      state = merged;
    }
    await _persist(merged);
  }

  Future<void> _persist(Set<String> ids) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_kFavoritesKey, ids.toList());

    final user = ref.read(authStateProvider).valueOrNull;
    if (user != null) {
      await ref.read(favoritesRepositoryProvider).setFavorites(user.uid, ids);
    }
  }
}

/// Lista de productos favoritos (resuelve los IDs contra el catálogo).
final favoriteProductsProvider = FutureProvider<List<Product>>((ref) async {
  final ids = ref.watch(favoritesControllerProvider).toList();
  if (ids.isEmpty) return const [];
  final result = await ref
      .watch(catalogRepositoryProvider)
      .getProductsByIds(ids);
  return result.fold((f) => throw f, (data) => data);
});
