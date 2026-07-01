import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/app_user.dart';
import '../repositories/auth_repository.dart';

/// Casos de uso de autenticación.
///
/// Cada clase encapsula una acción de negocio y delega en [AuthRepository].
/// Aunque son finos, mantenerlos como use cases respeta Clean Architecture y
/// facilita testear la lógica de presentación con dobles de prueba.

// ───────────────────────── Parámetros ─────────────────────────

class EmailSignInParams extends Equatable {
  const EmailSignInParams({required this.email, required this.password});
  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class EmailRegisterParams extends Equatable {
  const EmailRegisterParams({
    required this.name,
    required this.email,
    required this.password,
  });
  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

// ───────────────────────── Use cases ─────────────────────────

class SignInWithEmail implements UseCase<AppUser, EmailSignInParams> {
  const SignInWithEmail(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AppUser>> call(EmailSignInParams params) =>
      _repo.signInWithEmail(email: params.email, password: params.password);
}

class RegisterWithEmail implements UseCase<AppUser, EmailRegisterParams> {
  const RegisterWithEmail(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AppUser>> call(EmailRegisterParams params) =>
      _repo.registerWithEmail(
        name: params.name,
        email: params.email,
        password: params.password,
      );
}

class SignInWithGoogle implements UseCase<AppUser, NoParams> {
  const SignInWithGoogle(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) =>
      _repo.signInWithGoogle();
}

class SignInWithApple implements UseCase<AppUser, NoParams> {
  const SignInWithApple(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, AppUser>> call(NoParams params) =>
      _repo.signInWithApple();
}

class SendPasswordReset implements UseCase<Unit, String> {
  const SendPasswordReset(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(String email) =>
      _repo.sendPasswordReset(email);
}

class SignOut implements UseCase<Unit, NoParams> {
  const SignOut(this._repo);
  final AuthRepository _repo;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repo.signOut();
}
