/**
 * Repositorio de pedidos (colección `pedidos`).
 *
 * Lo usan el panel admin (Fase 7), Mercado Pago (Fase 8) y notificaciones
 * (Fase 10). Las escrituras de estado registran además el historial.
 */
import { db, FieldValue, Timestamp } from '../config/firebase.js';
import { COLLECTIONS, ORDER_STATUS } from '../shared/constants/orderStates.js';

const col = () => db.collection(COLLECTIONS.ORDERS);

/** Genera un número de pedido legible y secuencial: `TC-2026-000123`. */
async function nextOrderNumber() {
  const ref = db.collection(COLLECTIONS.CONFIG).doc('counters');
  const seq = await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const current = (snap.exists && snap.data().orders) || 0;
    const next = current + 1;
    tx.set(ref, { orders: next }, { merge: true });
    return next;
  });
  return `TC-${new Date().getFullYear()}-${String(seq).padStart(6, '0')}`;
}

export const orderRepository = {
  async getById(id) {
    const doc = await col().doc(id).get();
    return doc.exists ? { id: doc.id, ...doc.data() } : null;
  },

  /** Crea un pedido con estado inicial `pending` y su historial. */
  async create(data) {
    const orderNumber = await nextOrderNumber();
    const ref = col().doc();
    const now = Timestamp.now();
    await ref.set({
      ...data,
      orderNumber,
      status: ORDER_STATUS.PENDING,
      statusHistory: [{ status: ORDER_STATUS.PENDING, at: now, note: null }],
      stockApplied: false,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { id: ref.id, orderNumber };
  },

  /** Actualización parcial. Usa `update()` para soportar rutas con punto
   *  (p. ej. `'payment.status'`) como campos anidados reales. El pedido ya
   *  existe en todos los flujos que la invocan. */
  async update(id, data) {
    await col().doc(id).update({
      ...data,
      updatedAt: FieldValue.serverTimestamp(),
    });
  },

  /** Lista pedidos, opcionalmente filtrados por estado, más recientes primero. */
  async list({ status, limit = 50 } = {}) {
    let query = col();
    if (status) query = query.where('status', '==', status);
    query = query.orderBy('createdAt', 'desc').limit(limit);
    const snap = await query.get();
    return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  },

  /** Lee todos los pedidos (para estadísticas). Acotar en producción real. */
  async all({ limit = 1000 } = {}) {
    const snap = await col().limit(limit).get();
    return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
  },

  /** Cambia el estado de un pedido y agrega la transición al historial. */
  async updateStatus(id, status, note = null) {
    await col().doc(id).update({
      status,
      updatedAt: FieldValue.serverTimestamp(),
      statusHistory: FieldValue.arrayUnion({
        status,
        at: Timestamp.now(),
        note,
      }),
    });
    return { id, status };
  },
};
