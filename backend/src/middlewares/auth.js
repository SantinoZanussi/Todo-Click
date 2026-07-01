/**
 * Middlewares de autenticación y autorización.
 *
 * `verifyFirebaseToken` valida el ID token de Firebase que la app envía en el
 * header `Authorization: Bearer <token>` y adjunta `req.user`. `requireAdmin`
 * exige que el custom claim `role` sea `admin` — la verificación de permisos
 * se hace SIEMPRE contra el claim del token, nunca contra Firestore.
 */
import { authAdmin } from '../config/firebase.js';
import { ApiError } from '../shared/utils/ApiError.js';

export async function verifyFirebaseToken(req, _res, next) {
  try {
    const header = req.headers.authorization ?? '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) {
      throw ApiError.unauthorized('Falta el token de autenticación.');
    }

    const decoded = await authAdmin.verifyIdToken(token);
    req.user = {
      uid: decoded.uid,
      email: decoded.email ?? null,
      role: decoded.role ?? 'client',
      claims: decoded,
    };
    next();
  } catch (err) {
    if (err instanceof ApiError) return next(err);
    next(ApiError.unauthorized('Token inválido o expirado.'));
  }
}

export function requireAdmin(req, _res, next) {
  if (req.user?.role !== 'admin') {
    return next(ApiError.forbidden('Se requiere rol de administrador.'));
  }
  next();
}

/**
 * Autenticación OPCIONAL: si viene un token válido adjunta `req.user`, pero no
 * falla si no hay sesión (necesario para compras de invitado en el checkout).
 */
export async function optionalAuth(req, _res, next) {
  const header = req.headers.authorization ?? '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) return next();
  try {
    const decoded = await authAdmin.verifyIdToken(token);
    req.user = {
      uid: decoded.uid,
      email: decoded.email ?? null,
      role: decoded.role ?? 'client',
    };
  } catch {
    // Token inválido → seguimos como invitado.
  }
  next();
}
