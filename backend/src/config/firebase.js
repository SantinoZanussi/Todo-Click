/**
 * Inicialización del Firebase Admin SDK (singleton).
 *
 * El Admin SDK IGNORA las reglas de seguridad de Firestore: por eso vive solo
 * en el backend y es el único autorizado a escribir datos sensibles (precios,
 * stock, estados de pedido, custom claims).
 *
 * Estrategia de credenciales (en orden de prioridad):
 *  1. FIREBASE_SERVICE_ACCOUNT_JSON  → JSON completo en una variable (ideal en
 *     Cloud Run / Railway, donde no se sube un archivo).
 *  2. GOOGLE_APPLICATION_CREDENTIALS → ruta a un archivo .json local.
 *  3. Application Default Credentials → entorno Google con ADC ya configurado.
 */
import admin from 'firebase-admin';
import { readFileSync } from 'node:fs';

import { env } from './env.js';
import { logger } from '../shared/utils/logger.js';

/** Resuelve el objeto `credential` según las variables disponibles. */
function resolveCredential() {
  // 1. JSON inline
  if (env.firebase.serviceAccountJson) {
    try {
      const parsed = JSON.parse(env.firebase.serviceAccountJson);
      return admin.credential.cert(parsed);
    } catch (e) {
      throw new Error(
        '[firebase] FIREBASE_SERVICE_ACCOUNT_JSON no es un JSON válido.',
      );
    }
  }

  // 2. Ruta a archivo
  if (env.firebase.credentialsPath) {
    const raw = readFileSync(env.firebase.credentialsPath, 'utf8');
    return admin.credential.cert(JSON.parse(raw));
  }

  // 3. ADC (entorno Google)
  logger.warn(
    '[firebase] Sin credenciales explícitas; usando Application Default Credentials.',
  );
  return admin.credential.applicationDefault();
}

// Evita re-inicializar en hot-reload (`node --watch`).
const app = admin.apps.length
  ? admin.app()
  : admin.initializeApp({
      credential: resolveCredential(),
      projectId: env.firebase.projectId || undefined,
    });

export const firebaseApp = app;

/** Firestore (Admin). */
export const db = admin.firestore(app);
db.settings({ ignoreUndefinedProperties: true });

/** Firebase Auth (Admin) — para verificar tokens y setear custom claims. */
export const authAdmin = admin.auth(app);

/** Firebase Cloud Messaging — para enviar push (Fase 10). */
export const messaging = admin.messaging(app);

/** Helpers de Firestore reutilizados en repositorios. */
export const FieldValue = admin.firestore.FieldValue;
export const Timestamp = admin.firestore.Timestamp;
