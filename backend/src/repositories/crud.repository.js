/**
 * Fábrica de repositorios CRUD genéricos sobre Firestore (Admin SDK).
 *
 * Reutilizable para productos, categorías, marcas, cupones y promociones, que
 * comparten las mismas operaciones básicas. Casos especiales (p. ej. generar
 * `searchKeywords`) se resuelven en la capa de servicio/controlador.
 */
import { db, FieldValue } from '../config/firebase.js';

export function crudRepository(collectionName) {
  const col = () => db.collection(collectionName);

  return {
    async list({ limit = 200 } = {}) {
      const snap = await col().limit(limit).get();
      return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
    },

    async getById(id) {
      const doc = await col().doc(id).get();
      return doc.exists ? { id: doc.id, ...doc.data() } : null;
    },

    /** Crea un documento (id opcional para usar un slug/código como id). */
    async create(data, id) {
      const ref = id ? col().doc(id) : col().doc();
      await ref.set({
        ...data,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      });
      return { id: ref.id };
    },

    async update(id, data) {
      await col().doc(id).set(
        { ...data, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
      return { id };
    },

    async remove(id) {
      await col().doc(id).delete();
    },

    /** Borrado lógico: marca `isActive: false`. */
    async softDelete(id) {
      await col().doc(id).set(
        { isActive: false, updatedAt: FieldValue.serverTimestamp() },
        { merge: true },
      );
    },
  };
}
