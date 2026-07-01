import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/brand.dart';
import '../entities/category.dart';
import '../entities/product.dart';
import '../entities/product_query.dart';

/// Contrato de acceso al catálogo (productos, categorías, marcas).
abstract interface class CatalogRepository {
  Future<Either<Failure, List<Category>>> getCategories();

  Future<Either<Failure, List<Brand>>> getBrands();

  /// Productos destacados para el home.
  Future<Either<Failure, List<Product>>> getFeaturedProducts({int limit});

  /// Productos en oferta (mayor descuento primero).
  Future<Either<Failure, List<Product>>> getOnSaleProducts({int limit});

  Future<Either<Failure, Product>> getProductById(String id);

  /// Búsqueda/listado con filtros (ver [ProductQuery]).
  Future<Either<Failure, List<Product>>> queryProducts(ProductQuery query);

  /// Productos por lista de IDs (para favoritos).
  Future<Either<Failure, List<Product>>> getProductsByIds(List<String> ids);
}
