/**
 * Controlador del panel de administración.
 *
 * Todas las rutas que lo usan están protegidas por `verifyFirebaseToken` +
 * `requireAdmin`. Concentra las ESCRITURAS sensibles (las lecturas de listados
 * las hace la app directamente contra Firestore, permitido por las reglas para
 * administradores).
 */
import { authAdmin, Timestamp } from '../config/firebase.js';
import { signUpload } from '../config/cloudinary.js';
import { COLLECTIONS, ORDER_STATUS } from '../shared/constants/orderStates.js';
import { crudRepository } from '../repositories/crud.repository.js';
import { orderRepository } from '../repositories/order.repository.js';
import { userRepository } from '../repositories/user.repository.js';
import { notificationService } from '../services/notification.service.js';
import { statsService } from '../services/stats.service.js';
import { buildSearchKeywords } from '../shared/utils/searchKeywords.js';
import { ApiError } from '../shared/utils/ApiError.js';

const products = crudRepository(COLLECTIONS.PRODUCTS);
const categories = crudRepository(COLLECTIONS.CATEGORIES);
const brands = crudRepository(COLLECTIONS.BRANDS);
const coupons = crudRepository(COLLECTIONS.COUPONS);
const promotions = crudRepository(COLLECTIONS.PROMOTIONS);

const VALID_ORDER_STATUSES = new Set(Object.values(ORDER_STATUS));

/** Normaliza el payload de un producto y (re)genera sus keywords de búsqueda. */
function buildProductData(body) {
  const data = { ...body };
  data.searchKeywords = buildSearchKeywords(body.name, body.description);
  if (data.isActive === undefined) data.isActive = true;
  return data;
}

/** Convierte campos de fecha (ISO string) a Timestamp de Firestore. */
function withDates(body, fields = ['validFrom', 'validUntil']) {
  const data = { ...body };
  for (const f of fields) {
    if (typeof data[f] === 'string' && data[f]) {
      data[f] = Timestamp.fromDate(new Date(data[f]));
    }
  }
  return data;
}

export const adminController = {
  // ── Uploads (Cloudinary) ──
  uploadSignature(req, res) {
    res.json(signUpload({ folder: req.body?.folder }));
  },

  // ── Estadísticas ──
  async stats(_req, res) {
    res.json(await statsService.dashboard());
  },

  // ── Productos ──
  async createProduct(req, res) {
    const result = await products.create(buildProductData(req.body));
    res.status(201).json(result);
  },
  async updateProduct(req, res) {
    const result = await products.update(req.params.id, buildProductData(req.body));
    res.json(result);
  },
  async deleteProduct(req, res) {
    await products.softDelete(req.params.id);
    res.json({ id: req.params.id, deleted: true });
  },

  // ── Categorías ──
  async createCategory(req, res) {
    const { slug, ...rest } = req.body;
    const result = await categories.create({ slug, ...rest }, slug);
    res.status(201).json(result);
  },
  async updateCategory(req, res) {
    res.json(await categories.update(req.params.id, req.body));
  },
  async deleteCategory(req, res) {
    await categories.softDelete(req.params.id);
    res.json({ id: req.params.id, deleted: true });
  },

  // ── Marcas ──
  async createBrand(req, res) {
    const { slug, ...rest } = req.body;
    const result = await brands.create({ slug, ...rest }, slug);
    res.status(201).json(result);
  },
  async updateBrand(req, res) {
    res.json(await brands.update(req.params.id, req.body));
  },
  async deleteBrand(req, res) {
    await brands.softDelete(req.params.id);
    res.json({ id: req.params.id, deleted: true });
  },

  // ── Cupones (doc id = código en mayúsculas) ──
  async createCoupon(req, res) {
    const code = String(req.body.code ?? '').trim().toUpperCase();
    if (!code) throw ApiError.badRequest('Código de cupón requerido.');
    const result = await coupons.create(
      withDates({ ...req.body, code, usedCount: req.body.usedCount ?? 0 }),
      code,
    );
    res.status(201).json(result);
  },
  async updateCoupon(req, res) {
    res.json(await coupons.update(req.params.id, withDates(req.body)));
  },
  async deleteCoupon(req, res) {
    await coupons.remove(req.params.id);
    res.json({ id: req.params.id, deleted: true });
  },

  // ── Promociones ──
  async createPromotion(req, res) {
    const result = await promotions.create(withDates(req.body));
    res.status(201).json(result);
  },
  async updatePromotion(req, res) {
    res.json(await promotions.update(req.params.id, withDates(req.body)));
  },
  async deletePromotion(req, res) {
    await promotions.remove(req.params.id);
    res.json({ id: req.params.id, deleted: true });
  },

  // ── Pedidos ──
  async updateOrderStatus(req, res) {
    const { status, note } = req.body;
    if (!VALID_ORDER_STATUSES.has(status)) {
      throw ApiError.badRequest('Estado de pedido inválido.');
    }
    const result = await orderRepository.updateStatus(
      req.params.id,
      status,
      note ?? null,
    );
    // Notificar al cliente el cambio de estado (push + historial).
    const order = await orderRepository.getById(req.params.id);
    if (order) {
      await notificationService
        .notifyOrderStatus(order, order.payment?.status)
        .catch(() => {});
    }
    res.json(result);
  },

  async setOrderTracking(req, res) {
    const { trackingCode, carrier } = req.body;
    await orderRepository.update(req.params.id, {
      'shipping.trackingCode': trackingCode ?? null,
      'shipping.carrier': carrier ?? 'Correo Argentino',
    });
    res.json({ id: req.params.id, trackingCode: trackingCode ?? null });
  },

  // ── Usuarios ──
  async setUserRole(req, res) {
    const { uid } = req.params;
    const role = req.body.role === 'admin' ? 'admin' : 'client';
    const user = await authAdmin.getUser(uid);
    await authAdmin.setCustomUserClaims(uid, {
      ...(user.customClaims ?? {}),
      role,
    });
    await userRepository.upsert(uid, { role });
    res.json({ uid, role });
  },

  // ── Notificaciones ──
  async broadcastPromo(req, res) {
    const { title, body } = req.body;
    if (!title || !body) {
      throw ApiError.badRequest('Título y mensaje son requeridos.');
    }
    res.json(await notificationService.sendPromo({ title, body }));
  },
};
