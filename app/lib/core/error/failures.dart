import 'package:equatable/equatable.dart';

/// Representa un error de dominio "esperado" que viaja por la capa de
/// presentación de forma controlada.
///
/// Convención de Clean Architecture en TodoClick:
///  - La capa de **datos** lanza [Exception]s (ver `exceptions.dart`).
///  - Los **repositorios** capturan esas excepciones y devuelven
///    `Either<Failure, T>` (paquete `dartz`) hacia el dominio.
///  - La capa de **presentación** nunca ve excepciones crudas, solo
///    [Failure]s con un mensaje listo para mostrar al usuario.
sealed class Failure extends Equatable {
  const Failure(this.message, {this.code});

  /// Mensaje apto para mostrar al usuario (en español).
  final String message;

  /// Código técnico opcional (p. ej. código de error de Firebase).
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Error de red / conectividad.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'Sin conexión. Revisá tu internet e intentá de nuevo.',
    String? code,
  ]) : super(code: code);
}

/// Error proveniente del servidor / backend (HTTP 4xx-5xx no esperados).
class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Ocurrió un error en el servidor. Intentá más tarde.',
    String? code,
  ]) : super(code: code);
}

/// Error de autenticación (credenciales inválidas, sesión expirada, etc.).
class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'No pudimos validar tu identidad.',
    String? code,
  ]) : super(code: code);
}

/// Error de validación de datos de entrada.
class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Los datos ingresados no son válidos.',
    String? code,
  ]) : super(code: code);
}

/// Recurso no encontrado (404 / documento inexistente).
class NotFoundFailure extends Failure {
  const NotFoundFailure([
    super.message = 'No encontramos lo que buscabas.',
    String? code,
  ]) : super(code: code);
}

/// Error de caché / almacenamiento local.
class CacheFailure extends Failure {
  const CacheFailure([
    super.message = 'Error al acceder a los datos locales.',
    String? code,
  ]) : super(code: code);
}

/// Fallback para errores inesperados no clasificados.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'Algo salió mal. Intentá nuevamente.',
    String? code,
  ]) : super(code: code);
}
