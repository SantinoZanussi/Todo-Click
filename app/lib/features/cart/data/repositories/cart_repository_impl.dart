import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/cart_repository.dart';
import '../models/cart_item_model.dart';

const _kCartKey = 'cart_v1';

/// Implementación de [CartRepository] con SharedPreferences (local) y Firestore
/// (remoto). El carrito local se guarda como JSON; el remoto como array de
/// ítems en `carritos/{uid}`.
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({
    required SharedPreferences prefs,
    required FirebaseFirestore firestore,
  }) : _prefs = prefs,
       _firestore = firestore;

  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      _firestore.collection(FirestoreCollections.carts).doc(uid);

  @override
  Cart readLocal() {
    final raw = _prefs.getString(_kCartKey);
    if (raw == null || raw.isEmpty) return Cart.empty;
    try {
      final list = (jsonDecode(raw) as List)
          .whereType<Map>()
          .map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e)))
          .cast<CartItem>()
          .toList();
      return Cart(items: list);
    } catch (_) {
      return Cart.empty;
    }
  }

  @override
  Future<void> saveLocal(Cart cart) async {
    final encoded = jsonEncode(_itemsToMaps(cart));
    await _prefs.setString(_kCartKey, encoded);
  }

  @override
  Future<Cart> readRemote(String uid) async {
    final snap = await _doc(uid).get();
    final items = (snap.data()?['items'] as List?) ?? const [];
    return Cart(
      items: items
          .whereType<Map>()
          .map((e) => CartItemModel.fromMap(Map<String, dynamic>.from(e)))
          .cast<CartItem>()
          .toList(),
    );
  }

  @override
  Future<void> saveRemote(String uid, Cart cart) async {
    await _doc(uid).set({
      'items': _itemsToMaps(cart),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<Map<String, dynamic>> _itemsToMaps(Cart cart) =>
      cart.items.map((i) => CartItemModel.fromEntity(i).toMap()).toList();
}
