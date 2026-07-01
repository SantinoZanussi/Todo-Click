/**
 * Controlador de pagos (Mercado Pago Checkout Pro).
 */
import { paymentService } from '../services/payment.service.js';

export const paymentController = {
  /** Crea el pedido + la preferencia de Checkout Pro. */
  async checkout(req, res) {
    const result = await paymentService.createCheckout(req.body, req.user);
    res.status(201).json(result);
  },

  /** Webhook de notificaciones de pago de Mercado Pago. */
  async webhook(req, res) {
    const result = await paymentService.handleWebhook({
      query: req.query,
      body: req.body,
      headers: req.headers,
    });
    res.status(200).json(result);
  },

  /** Estado de un pedido (para que la app consulte tras volver del checkout). */
  async status(req, res) {
    res.json(await paymentService.getOrderStatus(req.params.orderId));
  },
};
