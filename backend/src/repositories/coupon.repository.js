/**
 * Repositorio de cupones (colección `cupones`, doc id = código en mayúsculas).
 */
import { db, FieldValue } from '../config/firebase.js';
import { COLLECTIONS } from '../shared/constants/orderStates.js';

const collection = () => db.collection(COLLECTIONS.COUPONS);

export const couponRepository = {
  async getByCode(code) {
    const snap = await collection().doc(code).get();
    return snap.exists ? { id: snap.id, ...snap.data() } : null;
  },

  /** Incrementa el contador de usos (al confirmarse un pedido — Fase 8). */
  async incrementUsage(code) {
    await collection().doc(code).update({
      usedCount: FieldValue.increment(1),
    });
  },
};
