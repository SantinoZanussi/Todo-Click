/**
 * Error de aplicación con código HTTP asociado.
 *
 * Los controladores/servicios lanzan `ApiError` y el middleware de manejo de
 * errores (`middlewares/errorHandler.js`) lo traduce a una respuesta JSON
 * consistente. Errores no controlados se tratan como 500.
 */
export class ApiError extends Error {
  /**
   * @param {number} statusCode  Código HTTP (400, 401, 404, 409, 500...).
   * @param {string} message     Mensaje legible para el cliente.
   * @param {object} [options]
   * @param {string} [options.code]     Código de error de negocio (p. ej. "COUPON_EXPIRED").
   * @param {unknown} [options.details] Detalles adicionales (errores de validación, etc.).
   */
  constructor(statusCode, message, { code, details } = {}) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.code = code;
    this.details = details;
    this.isOperational = true; // distingue errores esperados de bugs
    Error.captureStackTrace(this, this.constructor);
  }

  static badRequest(message, opts) {
    return new ApiError(400, message, opts);
  }

  static unauthorized(message = 'No autorizado', opts) {
    return new ApiError(401, message, opts);
  }

  static forbidden(message = 'Acceso denegado', opts) {
    return new ApiError(403, message, opts);
  }

  static notFound(message = 'Recurso no encontrado', opts) {
    return new ApiError(404, message, opts);
  }

  static conflict(message, opts) {
    return new ApiError(409, message, opts);
  }

  static internal(message = 'Error interno del servidor', opts) {
    return new ApiError(500, message, opts);
  }
}
