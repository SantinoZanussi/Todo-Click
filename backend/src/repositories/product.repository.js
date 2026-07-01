/**
 * Repositorio de productos para operaciones del flujo de compra (lectura de
 * precios/stock reales y descuento de stock al pagar).
 */
import { db, FieldValue } from '../config/firebase.js';
import { COLLECTIONS } from '../shared/constants/orderStates.js';

const col = () => db.collection(COLLECTIONS.PRODUCTS);

export const productRepository = {
  async getById(id) {
    const doc = await col().doc(id).get();
    return doc.exists ? { id: doc.id, ...doc.data() } : null;
  },

  /**
   * Descuenta stock e incrementa `soldCount` para una lista de ítems
   * `[{ productId, quantity }]`, en un único batch atómico.
   */
  async applyStockDecrements(items) {
    if (!items.length) return;
    const batch = db.batch();
    for (const item of items) {
      batch.update(col().doc(item.productId), {
        stock: FieldValue.increment(-item.quantity),
        soldCount: FieldValue.increment(item.quantity),
        updatedAt: FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  },
};
