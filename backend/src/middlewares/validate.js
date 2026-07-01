/**
 * Middleware que recolecta los errores de express-validator y, si hay alguno,
 * responde con 400 + el detalle. Se coloca después de las reglas de validación
 * en cada ruta.
 */
import { validationResult } from 'express-validator';

import { ApiError } from '../shared/utils/ApiError.js';

export function validate(req, _res, next) {
  const result = validationResult(req);
  if (!result.isEmpty()) {
    return next(
      ApiError.badRequest('Datos inválidos.', {
        code: 'VALIDATION_ERROR',
        details: result.array().map((e) => ({ field: e.path, msg: e.msg })),
      }),
    );
  }
  next();
}
