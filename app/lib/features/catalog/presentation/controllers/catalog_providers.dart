import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/app_providers.dart';
import '../../data/datasources/catalog_remote_datasource.dart';
import '../../data/repositories/catalog_repository_impl.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_query.dart';
import '../../domain/repositories/catalog_repository.dart';

// ───────────────────────── Infraestructura ──────────────────────────────────

final catalogRemoteDataSourceProvider = Provider<CatalogRemoteDataSource>(
  (ref) => CatalogRemoteDataSource(ref.watch(firestoreProvider)),
);

final catalogRepositoryProvider = Provider<CatalogRepository>(
  (ref) => CatalogRepositoryImpl(ref.watch(catalogRemoteDataSourceProvider)),
);

// ───────────────────────── Datos del catálogo ───────────────────────────────
// Convención: los FutureProviders desempaquetan el `Either`; ante un `Failure`
// lo lanzan para que el `AsyncValue` quede en estado de error y la UI lo maneje.

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).getCategories();
  return result.fold((f) => throw f, (data) => data);
});

final brandsProvider = FutureProvider<List<Brand>>((ref) async {
  final result = await ref.watch(catalogRepositoryProvider).getBrands();
  return result.fold((f) => throw f, (data) => data);
});

final featuredProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref
      .watch(catalogRepositoryProvider)
      .getFeaturedProducts(limit: 10);
  return result.fold((f) => throw f, (data) => data);
});

final onSaleProductsProvider = FutureProvider<List<Product>>((ref) async {
  final result = await ref
      .watch(catalogRepositoryProvider)
      .getOnSaleProducts(limit: 10);
  return result.fold((f) => throw f, (data) => data);
});

/// Detalle de un producto por id.
final productByIdProvider = FutureProvider.family<Product, String>((
  ref,
  id,
) async {
  final result = await ref.watch(catalogRepositoryProvider).getProductById(id);
  return result.fold((f) => throw f, (data) => data);
});

/// Resultados de una búsqueda/listado según [ProductQuery].
final productsQueryProvider =
    FutureProvider.family<List<Product>, ProductQuery>((ref, query) async {
      final result = await ref
          .watch(catalogRepositoryProvider)
          .queryProducts(query);
      return result.fold((f) => throw f, (data) => data);
    });
