import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_query.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';

/// Implementación de [CatalogRepository] sobre [CatalogRemoteDataSource].
class CatalogRepositoryImpl implements CatalogRepository {
  const CatalogRepositoryImpl(this._remote);

  final CatalogRemoteDataSource _remote;

  @override
  Future<Either<Failure, List<Category>>> getCategories() =>
      _guard(_remote.getCategories);

  @override
  Future<Either<Failure, List<Brand>>> getBrands() => _guard(_remote.getBrands);

  @override
  Future<Either<Failure, List<Product>>> getFeaturedProducts({
    int limit = 10,
  }) => _guard(() => _remote.getFeaturedProducts(limit: limit));

  @override
  Future<Either<Failure, List<Product>>> getOnSaleProducts({int limit = 10}) =>
      _guard(() => _remote.getOnSaleProducts(limit: limit));

  @override
  Future<Either<Failure, Product>> getProductById(String id) =>
      _guard(() => _remote.getProductById(id));

  @override
  Future<Either<Failure, List<Product>>> queryProducts(ProductQuery query) =>
      _guard(() => _remote.queryProducts(query));

  @override
  Future<Either<Failure, List<Product>>> getProductsByIds(List<String> ids) =>
      _guard(() => _remote.getProductsByIds(ids));

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on NotFoundException catch (e) {
      return Left(NotFoundFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, e.code));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
