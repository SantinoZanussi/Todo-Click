/**
 * Estados del pedido — ESPEJO de `app/lib/core/enums/order_status.dart`.
 *
 * ⚠️ Mantener sincronizado con el enum de Flutter. Las claves (string) son el
 * contrato compartido que se persiste en Firestore; deben coincidir
 * exactamente entre frontend y backend.
 */
export const ORDER_STATUS = Object.freeze({
  PENDING: 'pending',
  PAYMENT_PENDING: 'payment_pending',
  PAID: 'paid',
  PREPARING: 'preparing',
  DISPATCHED: 'dispatched',
  IN_TRANSIT: 'in_transit',
  DELIVERED: 'delivered',
  CANCELLED: 'cancelled',
  REFUNDED: 'refunded',
});

/** Estados de pago, alineados con los que reporta Mercado Pago. */
export const PAYMENT_STATUS = Object.freeze({
  NONE: 'none',
  PENDING: 'pending',
  APPROVED: 'approved',
  AUTHORIZED: 'authorized',
  IN_PROCESS: 'in_process',
  REJECTED: 'rejected',
  CANCELLED: 'cancelled',
  REFUNDED: 'refunded',
  CHARGED_BACK: 'charged_back',
});

/**
 * Mapa de transición: dado el `status` de pago de Mercado Pago, a qué estado
 * de pedido debe pasar. Usado por el webhook (Fase 8).
 */
export const PAYMENT_TO_ORDER_STATUS = Object.freeze({
  [PAYMENT_STATUS.APPROVED]: ORDER_STATUS.PAID,
  [PAYMENT_STATUS.PENDING]: ORDER_STATUS.PAYMENT_PENDING,
  [PAYMENT_STATUS.IN_PROCESS]: ORDER_STATUS.PAYMENT_PENDING,
  [PAYMENT_STATUS.AUTHORIZED]: ORDER_STATUS.PAYMENT_PENDING,
  [PAYMENT_STATUS.REJECTED]: ORDER_STATUS.PENDING,
  [PAYMENT_STATUS.CANCELLED]: ORDER_STATUS.CANCELLED,
  [PAYMENT_STATUS.REFUNDED]: ORDER_STATUS.REFUNDED,
  [PAYMENT_STATUS.CHARGED_BACK]: ORDER_STATUS.REFUNDED,
});

/** Nombres de colecciones de Firestore (espejo de FirestoreCollections en Dart). */
export const COLLECTIONS = Object.freeze({
  USERS: 'usuarios',
  PRODUCTS: 'productos',
  CATEGORIES: 'categorias',
  BRANDS: 'marcas',
  ORDERS: 'pedidos',
  FAVORITES: 'favoritos',
  CARTS: 'carritos',
  COUPONS: 'cupones',
  PROMOTIONS: 'promociones',
  NOTIFICATIONS: 'notificaciones',
  CONFIG: 'configuracion',
});
