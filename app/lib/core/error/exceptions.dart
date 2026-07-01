/// Excepciones de la capa de datos.
///
/// Estas se lanzan en datasources/servicios y se traducen a `Failure`
/// (ver `failures.dart`) dentro de los repositorios. La capa de
/// presentación nunca debería atrapar estas excepciones directamente.
library;

/// Error genérico originado en el servidor / backend.
class ServerException implements Exception {
  const ServerException([this.message = 'Server error', this.code]);
  final String message;
  final String? code;
}

/// Error de red / timeout / sin conexión.
class NetworkException implements Exception {
  const NetworkException([this.message = 'Network error']);
  final String message;
}

/// Error de autenticación (Firebase Auth, tokens, etc.).
class AuthException implements Exception {
  const AuthException([this.message = 'Auth error', this.code]);
  final String message;
  final String? code;
}

/// Error de caché / almacenamiento local.
class CacheException implements Exception {
  const CacheException([this.message = 'Cache error']);
  final String message;
}

/// Recurso no encontrado.
class NotFoundException implements Exception {
  const NotFoundException([this.message = 'Not found']);
  final String message;
}

/// Error de validación de datos.
class ValidationException implements Exception {
  const ValidationException([this.message = 'Validation error']);
  final String message;
}
