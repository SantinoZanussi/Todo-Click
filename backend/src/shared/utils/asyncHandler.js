/**
 * Envuelve un handler async para que cualquier promesa rechazada se delegue al
 * middleware de errores (`next(err)`), evitando try/catch repetidos en cada
 * controlador.
 *
 * Uso: `router.get('/x', asyncHandler(controller.x))`
 */
export const asyncHandler = (fn) => (req, res, next) =>
  Promise.resolve(fn(req, res, next)).catch(next);
