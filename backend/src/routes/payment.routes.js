/**
 * Rutas de pagos (`/api/payments`).
 *
 * `/checkout` usa autenticación opcional (compras de invitado permitidas).
 * `/webhook` es público (lo llama Mercado Pago) y valida la firma.
 */
import { Router } from 'express';

import { paymentController } from '../controllers/payment.controller.js';
import { optionalAuth } from '../middlewares/auth.js';
import { asyncHandler } from '../shared/utils/asyncHandler.js';

const router = Router();

router.post('/checkout', optionalAuth, asyncHandler(paymentController.checkout));
router.post('/webhook', asyncHandler(paymentController.webhook));
router.get('/status/:orderId', asyncHandler(paymentController.status));

export default router;
