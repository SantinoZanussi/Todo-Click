/**
 * Middlewares de manejo de errores y rutas no encontradas.
 *
 * Se registran al final de la cadena de Express (después de las rutas).
 */
import { ApiError } from '../shared/utils/ApiError.js';
import { logger } from '../shared/utils/logger.js';

/** 404 para cualquier ruta no matcheada. */
export function notFoundHandler(req, _res, next) {
  next(ApiError.notFound(`Ruta no encontrada: ${req.method} ${req.originalUrl}`));
}

/**
 * Manejador central de errores. Convierte cualquier error en una respuesta
 * JSON con forma consistente: `{ error: { message, code, details } }`.
 */
// eslint-disable-next-line no-unused-vars -- Express identifica el handler por aridad (4 args).
export function errorHandler(err, req, res, _next) {
  const isApiError = err instanceof ApiError;
  const statusCode = isApiError ? err.statusCode : 500;

  // Logueamos como warning los errores operativos esperados, como error los bugs.
  if (statusCode >= 500) {
    logger.error({ err, path: req.originalUrl }, 'Error no controlado');
  } else {
    logger.warn({ code: err.code, path: req.originalUrl }, err.message);
  }

  res.status(statusCode).json({
    error: {
      message: statusCode >= 500 && !isApiError
        ? 'Error interno del servidor'
        : err.message,
      code: err.code ?? null,
      details: err.details ?? null,
    },
  });
}
