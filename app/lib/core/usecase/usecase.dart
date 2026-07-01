import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../error/failures.dart';

/// Contrato base de un caso de uso (interactor) de la capa de dominio.
///
/// Cada caso de uso encapsula UNA acción de negocio (p. ej. `AddToCart`,
/// `GetProductById`). Recibe sus parámetros mediante [Params] y devuelve
/// `Either<Failure, Type>`: a la izquierda el error de dominio, a la derecha
/// el resultado exitoso.
///
/// Ejemplo:
/// ```dart
/// class GetProductById implements UseCase<Product, String> {
///   const GetProductById(this._repo);
///   final CatalogRepository _repo;
///
///   @override
///   Future<Either<Failure, Product>> call(String id) =>
///       _repo.getProductById(id);
/// }
/// ```
abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Variante síncrona / streaming para casos de uso que exponen un `Stream`.
abstract interface class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}

/// Marcador para casos de uso que no reciben parámetros.
///
/// Uso: `class GetCurrentUser implements UseCase<User, NoParams> { ... }`
/// e invocación `useCase(const NoParams())`.
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}
