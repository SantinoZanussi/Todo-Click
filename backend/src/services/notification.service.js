/**
 * Servicio de notificaciones: envía push vía FCM y persiste cada notificación
 * en la colección `notificaciones` (para el historial in-app del cliente).
 *
 * Las compras de invitado no reciben push (no hay cuenta/token).
 */
import { db, FieldValue, messaging } from '../config/firebase.js';
import { userRepository } from '../repositories/user.repository.js';
import {
  COLLECTIONS,
  ORDER_STATUS,
  PAYMENT_STATUS,
} from '../shared/constants/orderStates.js';
import { logger } from '../shared/utils/logger.js';

const PROMOS_TOPIC = 'promos';

/** Mensaje a mostrar según el estado del pedido / pago. */
function buildOrderMessage(orderStatus, paymentStatus) {
  if (paymentStatus === PAYMENT_STATUS.REJECTED) {
    return {
      type: 'payment_rejected',
      title: 'Pago rechazado',
      body: 'No pudimos procesar el pago de tu pedido. Intentá nuevamente.',
    };
  }
  switch (orderStatus) {
    case ORDER_STATUS.PAID:
      return {
        type: 'payment_approved',
        title: '¡Pago aprobado! 🎉',
        body: 'Confirmamos tu pago. ¡Estamos preparando tu pedido!',
      };
    case ORDER_STATUS.PREPARING:
      return {
        type: 'order_preparing',
        title: 'Preparando tu pedido 📦',
        body: 'Tu pedido está siendo preparado.',
      };
    case ORDER_STATUS.DISPATCHED:
    case ORDER_STATUS.IN_TRANSIT:
      return {
        type: 'order_shipped',
        title: 'Tu pedido va en camino 🚚',
        body: 'Ya despachamos tu pedido. Podés seguirlo desde la app.',
      };
    case ORDER_STATUS.DELIVERED:
      return {
        type: 'order_delivered',
        title: '¡Pedido entregado! ✅',
        body: 'Tu pedido fue entregado. ¡Gracias por comprar en TodoClick!',
      };
    default:
      return null;
  }
}

/** Convierte todos los valores del data payload a string (requisito de FCM). */
function stringifyData(data = {}) {
  return Object.fromEntries(
    Object.entries(data).map(([k, v]) => [k, String(v ?? '')]),
  );
}

export const notificationService = {
  /** Notifica al dueño de un pedido según su estado actual. */
  async notifyOrderStatus(order, paymentStatus) {
    if (!order.userId) return;
    const msg = buildOrderMessage(order.status, paymentStatus);
    if (!msg) return;
    await this.notifyUser(order.userId, {
      ...msg,
      data: {
        orderId: order.id,
        orderNumber: order.orderNumber,
        type: msg.type,
      },
    });
  },

  /** Envía push a todos los dispositivos del usuario + guarda el historial. */
  async notifyUser(uid, { title, body, type, data = {} }) {
    // 1. Persistir en `notificaciones`.
    await db.collection(COLLECTIONS.NOTIFICATIONS).add({
      userId: uid,
      type,
      title,
      body,
      data,
      read: false,
      readAt: null,
      createdAt: FieldValue.serverTimestamp(),
    });

    // 2. Push a los tokens del usuario.
    const user = await userRepository.getById(uid);
    const tokens = (user?.fcmTokens ?? []).filter(Boolean);
    if (tokens.length === 0) return;

    try {
      const res = await messaging.sendEachForMulticast({
        tokens,
        notification: { title, body },
        data: stringifyData({ ...data, type }),
      });
      await this._cleanupTokens(uid, tokens, res);
    } catch (err) {
      logger.warn({ err: err.message }, 'Error enviando push');
    }
  },

  /** Envía una promoción al tópico `promos` (todos los suscriptos). */
  async sendPromo({ title, body }) {
    await messaging.send({
      topic: PROMOS_TOPIC,
      notification: { title, body },
      data: stringifyData({ type: 'promo' }),
    });
    return { sent: true };
  },

  /** Elimina del usuario los tokens que FCM reportó como inválidos. */
  async _cleanupTokens(uid, tokens, batchResponse) {
    const invalid = [];
    batchResponse.responses.forEach((r, i) => {
      const code = r.error?.code;
      if (
        code === 'messaging/registration-token-not-registered' ||
        code === 'messaging/invalid-registration-token'
      ) {
        invalid.push(tokens[i]);
      }
    });
    if (invalid.length) {
      await db
        .collection(COLLECTIONS.USERS)
        .doc(uid)
        .update({ fcmTokens: FieldValue.arrayRemove(...invalid) });
    }
  },
};
