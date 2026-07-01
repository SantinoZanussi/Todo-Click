import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_query.dart';
import '../models/brand_model.dart';
import '../models/category_model.dart';
import '../models/product_model.dart';

/// Fuente de datos del catálogo sobre Firestore (solo lectura).
///
/// Estrategia de búsqueda: aplica el filtro PRIMARIO server-side (categoría,
/// marca o keyword) + `isActive` + orden + límite, y afina los filtros
/// secundarios (rango de precio, disponibilidad, texto completo) en cliente.
/// Así cubrimos las combinaciones sin requerir un índice por cada permutación.
class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _products =>
      _firestore.collection(FirestoreCollections.products);

  CollectionReference<Map<String, dynamic>> get _categories =>
      _firestore.collection(FirestoreCollections.categories);

  CollectionReference<Map<String, dynamic>> get _brands =>
      _firestore.collection(FirestoreCollections.brands);

  Future<List<Category>> getCategories() async {
    try {
      // Solo filtro por igualdad (índice automático) y ordeno en cliente para
      // no requerir un índice compuesto (isActive + order). Son pocas.
      final snap = await _categories.where('isActive', isEqualTo: true).get();
      final categories = snap.docs
          .map(CategoryModel.fromFirestore)
          .cast<Category>()
          .toList();
      categories.sort((a, b) => a.order.compareTo(b.order));
      return categories;
    } catch (e) {
      throw ServerException('No se pudieron cargar las categorías', '$e');
    }
  }

  Future<List<Brand>> getBrands() async {
    try {
      final snap = await _brands.where('isActive', isEqualTo: true).get();
      final brands = snap.docs.map(BrandModel.fromFirestore).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return brands;
    } catch (e) {
      throw ServerException('No se pudieron cargar las marcas', '$e');
    }
  }

  Future<List<Product>> getFeaturedProducts({int limit = 10}) async {
    try {
      final snap = await _products
          .where('isActive', isEqualTo: true)
          .where('isFeatured', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(ProductModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException('No se pudieron cargar los destacados', '$e');
    }
  }

  Future<List<Product>> getOnSaleProducts({int limit = 10}) async {
    try {
      final snap = await _products
          .where('isActive', isEqualTo: true)
          .where('isOnSale', isEqualTo: true)
          .orderBy('discountPercentage', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(ProductModel.fromFirestore).toList();
    } catch (e) {
      throw ServerException('No se pudieron cargar las ofertas', '$e');
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final doc = await _products.doc(id).get();
      if (!doc.exists) throw const NotFoundException('Producto no encontrado');
      return ProductModel.fromFirestore(doc);
    } on NotFoundException {
      rethrow;
    } catch (e) {
      throw ServerException('No se pudo cargar el producto', '$e');
    }
  }

  Future<List<Product>> getProductsByIds(List<String> ids) async {
    if (ids.isEmpty) return const [];
    try {
      // Firestore limita `whereIn` a 30 valores → consultamos en lotes.
      final results = <Product>[];
      for (var i = 0; i < ids.length; i += 30) {
        final batch = ids.sublist(i, (i + 30).clamp(0, ids.length));
        final snap = await _products
            .where(FieldPath.documentId, whereIn: batch)
            .get();
        results.addAll(snap.docs.map(ProductModel.fromFirestore));
      }
      return results;
    } catch (e) {
      throw ServerException('No se pudieron cargar los productos', '$e');
    }
  }

  Future<List<Product>> queryProducts(ProductQuery query) async {
    try {
      Query<Map<String, dynamic>> q = _products.where(
        'isActive',
        isEqualTo: true,
      );

      // ── Filtro primario (uno solo, server-side) ──
      if (query.hasText) {
        final token = _firstToken(query.searchText!);
        q = q.where('searchKeywords', arrayContains: token);
      } else if (query.categoryId != null) {
        q = q.where('categoryId', isEqualTo: query.categoryId);
        if (query.subcategoryId != null) {
          q = q.where('subcategoryId', isEqualTo: query.subcategoryId);
        }
      } else if (query.brandId != null) {
        q = q.where('brandId', isEqualTo: query.brandId);
      }

      // ── Orden server-side (cuando no choca con el array-contains) ──
      q = switch (query.sort) {
        ProductSort.priceAsc => q.orderBy('price'),
        ProductSort.priceDesc => q.orderBy('price', descending: true),
        ProductSort.discount => q.orderBy(
          'discountPercentage',
          descending: true,
        ),
        ProductSort.newest => q.orderBy('createdAt', descending: true),
        ProductSort.relevance => q,
      };

      final snap = await q.limit(query.limit).get();
      var products = snap.docs
          .map(ProductModel.fromFirestore)
          .cast<Product>()
          .toList();

      // ── Filtros secundarios (cliente) ──
      products = _refine(products, query);
      return products;
    } catch (e) {
      throw ServerException('No se pudo realizar la búsqueda', '$e');
    }
  }

  /// Afina en cliente: texto completo, marca/categoría (si el primario fue
  /// keyword), rango de precio, disponibilidad y oferta.
  List<Product> _refine(List<Product> input, ProductQuery query) {
    final text = query.searchText?.trim().toLowerCase();
    var result = input.where((p) {
      if (text != null && text.isNotEmpty) {
        final haystack = '${p.name} ${p.description}'.toLowerCase();
        if (!haystack.contains(text)) return false;
        if (query.categoryId != null && p.categoryId != query.categoryId) {
          return false;
        }
        if (query.brandId != null && p.brandId != query.brandId) return false;
      }
      if (query.inStockOnly && !p.hasStock) return false;
      if (query.onSaleOnly && !p.isOnSale) return false;
      final price = p.finalPrice;
      if (query.minPrice != null && price < query.minPrice!) return false;
      if (query.maxPrice != null && price > query.maxPrice!) return false;
      return true;
    }).toList();

    // Relevancia → priorizamos destacados y luego por nombre.
    if (query.sort == ProductSort.relevance) {
      result.sort((a, b) {
        if (a.isFeatured != b.isFeatured) return a.isFeatured ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    }
    return result;
  }

  /// Primer token normalizado del texto de búsqueda (para `array-contains`).
  String _firstToken(String text) =>
      text.trim().toLowerCase().split(RegExp(r'\s+')).first;
}
