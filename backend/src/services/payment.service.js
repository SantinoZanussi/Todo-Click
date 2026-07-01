/**
 * Lógica de pagos con Mercado Pago Checkout Pro.
 *
 * Flujo:
 *  1. `createCheckout` re-valida precios y stock CONTRA Firestore (nunca confía
 *     en los montos que manda el cliente), crea el pedido y la preferencia MP.
 *  2. `handleWebhook` recibe la notificación, consulta el pago real en MP,
 *     actualiza el estado del pedido y, si se aprobó, descuenta stock y suma el
 *     uso del cupón (de forma idempotente).
 */
import crypto from 'node:crypto';

import { env } from '../config/env.js';
import { mpPayment, mpPreference } from '../config/mercadopago.js';
import { couponRepository } from '../repositories/coupon.repository.js';
import { orderRepository } from '../repositories/order.repository.js';
import { productRepository } from '../repositories/product.repository.js';
import { couponService } from './coupon.service.js';
import { notificationService } from './notification.service.js';
import {
  PAYMENT_STATUS,
  PAYMENT_TO_ORDER_STATUS,
  ORDER_STATUS,
} from '../shared/constants/orderStates.js';
import { ApiError } from '../shared/utils/ApiError.js';
import { logger } from '../shared/utils/logger.js';
import { computeFinalPrice, round2 } from '../shared/utils/pricing.js';

export const paymentService = {
  async createCheckout(payload, user) {
    const { items = [], shipping = {}, couponCode } = payload;
    if (!Array.isArray(items) || items.length === 0) {
      throw ApiError.badRequest('El carrito está vacío.');
    }

    // 1. Re-validar productos, precios y stock contra Firestore.
    const orderItems = [];
    let subtotal = 0;
    for (const line of items) {
      const product = await productRepository.getById(line.productId);
      if (!product || product.isActive === false) {
        throw ApiError.badRequest(`Producto no disponible: ${line.productId}`);
      }
      const quantity = Math.max(1, Number(line.quantity) || 1);
      if ((product.stock ?? 0) < quantity) {
        throw ApiError.conflict(`Sin stock suficiente de "${product.name}".`);
      }
      const unitPrice = computeFinalPrice(product);
      subtotal += unitPrice * quantity;
      orderItems.push({
        productId: product.id,
        name: product.name,
        sku: product.sku ?? '',
        imageUrl: (product.images ?? [])[0] ?? null,
        unitPrice,
        quantity,
      });
    }
    subtotal = round2(subtotal);

    // 2. Cupón (re-validado server-side).
    let discount = 0;
    let appliedCoupon = null;
    if (couponCode) {
      const result = await couponService.validate(couponCode, subtotal);
      if (result.valid) {
        discount = round2(result.discount);
        appliedCoupon = result.code;
      }
    }

    const shippingCost = round2(Number(shipping.cost) || 0);
    const total = round2(subtotal - discount + shippingCost);

    // 3. Crear el pedido (estado pending).
    const { id: orderId, orderNumber } = await orderRepository.create({
      userId: user?.uid ?? null,
      items: orderItems,
      subtotal,
      discount,
      shippingCost,
      total,
      couponCode: appliedCoupon,
      shipping: {
        method: shipping.method ?? 'home_delivery',
        cost: shippingCost,
        carrier: shipping.carrier ?? 'Correo Argentino',
        address: shipping.address ?? null,
        branchId: shipping.branchId ?? null,
        estimatedDays: shipping.estimatedDays ?? null,
        trackingCode: null,
      },
      payment: { status: PAYMENT_STATUS.NONE, preferenceId: null, paymentId: null },
    });

    // 4. Crear la preferencia de Checkout Pro.
    //    El descuento se prorratea sobre los precios unitarios para que el total
    //    cobrado coincida exactamente con el del pedido.
    const factor = subtotal > 0 ? (subtotal - discount) / subtotal : 1;
    const preferenceItems = orderItems.map((i) => ({
      id: i.productId,
      title: i.name,
      quantity: i.quantity,
      unit_price: round2(i.unitPrice * factor),
      currency_id: 'ARS',
    }));

    // Las back_urls son opcionales: si no están configuradas, la preferencia
    // se crea igual y la app resuelve el resultado por polling. auto_return
    // solo se activa con una URL de éxito https (requisito de Mercado Pago).
    const backUrls = {};
    if (env.mercadoPago.successUrl) backUrls.success = env.mercadoPago.successUrl;
    if (env.mercadoPago.failureUrl) backUrls.failure = env.mercadoPago.failureUrl;
    if (env.mercadoPago.pendingUrl) backUrls.pending = env.mercadoPago.pendingUrl;

    const preference = await mpPreference.create({
      body: {
        items: preferenceItems,
        shipments: shippingCost > 0
          ? { cost: shippingCost, mode: 'not_specified' }
          : undefined,
        external_reference: orderId,
        metadata: { orderId, orderNumber },
        notification_url: env.mercadoPago.notificationUrl || undefined,
        back_urls: Object.keys(backUrls).length ? backUrls : undefined,
        auto_return: backUrls.success?.startsWith('https://')
          ? 'approved'
          : undefined,
      },
    });

    await orderRepository.update(orderId, {
      'payment.preferenceId': preference.id,
      status: ORDER_STATUS.PAYMENT_PENDING,
    });

    return {
      orderId,
      orderNumber,
      preferenceId: preference.id,
      initPoint: preference.init_point ?? preference.sandbox_init_point,
    };
  },

  async handleWebhook({ query, body, headers }) {
    const type = query.type ?? body.type ?? body.action?.split('.')?.[0];
    const paymentId = query['data.id'] ?? body.data?.id ?? body.id;
    if (type !== 'payment' || !paymentId) {
      return { ignored: true };
    }

    if (!verifySignature({ headers, query, paymentId })) {
      logger.warn('Webhook MP con firma inválida — se ignora.');
      throw ApiError.unauthorized('Firma de webhook inválida.');
    }

    const payment = await mpPayment.get({ id: paymentId });
    const orderId = payment.external_reference;
    if (!orderId) return { ignored: true };

    const order = await orderRepository.getById(orderId);
    if (!order) return { ignored: true };

    const paymentStatus = payment.status ?? PAYMENT_STATUS.PENDING;
    const newOrderStatus =
      PAYMENT_TO_ORDER_STATUS[paymentStatus] ?? ORDER_STATUS.PAYMENT_PENDING;

    await orderRepository.update(orderId, {
      status: newOrderStatus,
      'payment.status': paymentStatus,
      'payment.paymentId': String(payment.id),
      'payment.method': payment.payment_method_id ?? null,
      'payment.paidAt':
        paymentStatus === PAYMENT_STATUS.APPROVED ? new Date() : null,
    });
    await orderRepository.updateStatus(orderId, newOrderStatus, 'Webhook MP');

    // Efectos al aprobar (idempotente).
    if (paymentStatus === PAYMENT_STATUS.APPROVED && !order.stockApplied) {
      await productRepository.applyStockDecrements(
        (order.items ?? []).map((i) => ({
          productId: i.productId,
          quantity: i.quantity,
        })),
      );
      if (order.couponCode) {
        await couponRepository.incrementUsage(order.couponCode).catch(() => {});
      }
      await orderRepository.update(orderId, { stockApplied: true });
    }

    // Notificar al cliente (push + historial).
    await notificationService
      .notifyOrderStatus(
        { ...order, status: newOrderStatus },
        paymentStatus,
      )
      .catch((e) => logger.warn({ err: e.message }, 'notifyOrderStatus falló'));

    return { ok: true, orderId, status: newOrderStatus };
  },

  async getOrderStatus(orderId) {
    const order = await orderRepository.getById(orderId);
    if (!order) throw ApiError.notFound('Pedido no encontrado.');
    return {
      orderId: order.id,
      orderNumber: order.orderNumber,
      status: order.status,
      paymentStatus: order.payment?.status ?? PAYMENT_STATUS.NONE,
      total: order.total,
    };
  },
};

/**
 * Valida la firma del webhook (header `x-signature`). Si no hay secreto
 * configurado, se omite la validación (útil en desarrollo).
 */
function verifySignature({ headers, query, paymentId }) {
  const secret = env.mercadoPago.webhookSecret;
  if (!secret) return true;

  const signature = headers['x-signature'];
  const requestId = headers['x-request-id'];
  if (!signature) return false;

  const parts = Object.fromEntries(
    signature.split(',').map((p) => p.split('=').map((s) => s.trim())),
  );
  const ts = parts.ts;
  const hash = parts.v1;
  if (!ts || !hash) return false;

  const dataId = query['data.id'] ?? paymentId;
  const manifest = `id:${dataId};request-id:${requestId};ts:${ts};`;
  const expected = crypto
    .createHmac('sha256', secret)
    .update(manifest)
    .digest('hex');
  return crypto.timingSafeEqual(Buffer.from(hash), Buffer.from(expected));
}
