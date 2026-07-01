import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/repositories/favorites_repository.dart';

/// Implementación de [FavoritesRepository] sobre Firestore.
///
/// Modela un único documento por usuario: `favoritos/{uid}` con el campo
/// `productIds: string[]` (lectura/escritura simple desde la app).
class FavoritesRepositoryImpl implements FavoritesRepository {
  const FavoritesRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(FirestoreCollections.favorites).doc(uid);

  @override
  Future<Set<String>> getFavorites(String uid) async {
    final snap = await _doc(uid).get();
    final ids = (snap.data()?['productIds'] as List?)?.cast<String>();
    return ids?.toSet() ?? <String>{};
  }

  @override
  Future<void> setFavorites(String uid, Set<String> productIds) async {
    await _doc(uid).set({
      'productIds': productIds.toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
