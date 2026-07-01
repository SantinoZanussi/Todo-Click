import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementación de [AuthRepository] sobre [AuthRemoteDataSource].
///
/// Su responsabilidad es traducir las [AuthException] (y errores inesperados)
/// del datasource a [Failure]s del dominio, devolviendo siempre `Either`.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Stream<AppUser?> authStateChanges() => _remote.authStateChanges();

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() =>
      _guard(() => _remote.getCurrentUser());

  @override
  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() => _remote.signInWithEmail(email: email, password: password));

  @override
  Future<Either<Failure, AppUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) => _guard(
    () =>
        _remote.registerWithEmail(name: name, email: email, password: password),
  );

  @override
  Future<Either<Failure, AppUser>> signInWithGoogle() =>
      _guard(() => _remote.signInWithGoogle());

  @override
  Future<Either<Failure, AppUser>> signInWithApple() =>
      _guard(() => _remote.signInWithApple());

  @override
  Future<Either<Failure, Unit>> sendPasswordReset(String email) =>
      _guard(() async {
        await _remote.sendPasswordReset(email);
        return unit;
      });

  @override
  Future<Either<Failure, Unit>> signOut() => _guard(() async {
    await _remote.signOut();
    return unit;
  });

  /// Ejecuta [action] y normaliza errores a [Failure].
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() action) async {
    try {
      return Right(await action());
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message, e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
