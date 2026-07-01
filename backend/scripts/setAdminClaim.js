/**
 * Asigna (o revoca) el rol de administrador a un usuario.
 *
 * Setea el *custom claim* `role: "admin"` en Firebase Auth — la fuente de
 * verdad de permisos — y refleja el rol en el documento `usuarios/{uid}`.
 * El usuario debe re-loguearse (o refrescar el token) para que el claim surta
 * efecto en la app.
 *
 * Uso:
 *   cd backend && npm run set-admin -- <uid>            # promueve a admin
 *   cd backend && npm run set-admin -- <uid> --revoke   # vuelve a cliente
 */
import { authAdmin, db, FieldValue } from '../src/config/firebase.js';
import { COLLECTIONS } from '../src/shared/constants/orderStates.js';
import { logger } from '../src/shared/utils/logger.js';

async function main() {
  const uid = process.argv[2];
  const revoke = process.argv.includes('--revoke');

  if (!uid || uid.startsWith('--')) {
    logger.error('Falta el UID. Uso: npm run set-admin -- <uid> [--revoke]');
    process.exit(1);
  }

  const role = revoke ? 'client' : 'admin';

  // 1. Verificar que el usuario existe.
  const user = await authAdmin.getUser(uid);

  // 2. Custom claim (preservando otros claims existentes).
  await authAdmin.setCustomUserClaims(uid, {
    ...(user.customClaims ?? {}),
    role,
  });

  // 3. Reflejar en Firestore (informativo).
  await db.collection(COLLECTIONS.USERS).doc(uid).set(
    { role, updatedAt: FieldValue.serverTimestamp() },
    { merge: true },
  );

  logger.info(`✅ ${user.email ?? uid} → role="${role}". Debe re-loguearse.`);
  process.exit(0);
}

main().catch((err) => {
  logger.error({ err }, '❌ No se pudo actualizar el rol');
  process.exit(1);
});
