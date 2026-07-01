/**
 * Repositorio de usuarios — único punto de acceso a la colección `usuarios`
 * desde el backend (Admin SDK).
 */
import { db, FieldValue } from '../config/firebase.js';
import { COLLECTIONS } from '../shared/constants/orderStates.js';

const collection = () => db.collection(COLLECTIONS.USERS);

export const userRepository = {
  /** Devuelve el perfil del usuario o `null` si no existe. */
  async getById(uid) {
    const snap = await collection().doc(uid).get();
    return snap.exists ? { id: snap.id, ...snap.data() } : null;
  },

  /** Crea/actualiza (merge) el perfil del usuario. */
  async upsert(uid, data) {
    await collection().doc(uid).set(
      { ...data, updatedAt: FieldValue.serverTimestamp() },
      { merge: true },
    );
  },
};
