import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/app_user.dart';

/// Contrato de autenticación (capa de dominio).
///
/// La implementación (Firebase Auth + Firestore) vive en
/// `data/repositories/auth_repository_impl.dart`. La presentación depende solo
/// de esta interfaz, no de Firebase.
abstract interface class AuthRepository {
  /// Stream del usuario autenticado: emite el [AppUser] al iniciar sesión y
  /// `null` al cerrarla. Es la fuente de verdad del estado de sesión.
  Stream<AppUser?> authStateChanges();

  /// Usuario actual (sincrónico desde la última sesión persistida), o `null`.
  Future<Either<Failure, AppUser?>> getCurrentUser();

  Future<Either<Failure, AppUser>> signInWithEmail({
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> registerWithEmail({
    required String name,
    required String email,
    required String password,
  });

  Future<Either<Failure, AppUser>> signInWithGoogle();

  Future<Either<Failure, AppUser>> signInWithApple();

  /// Envía el email de recuperación de contraseña.
  Future<Either<Failure, Unit>> sendPasswordReset(String email);

  Future<Either<Failure, Unit>> signOut();
}
