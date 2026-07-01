/**
 * Rutas de cupones (`/api/coupons`).
 */
import { Router } from 'express';
import { body } from 'express-validator';

import { couponController } from '../controllers/coupon.controller.js';
import { validate } from '../middlewares/validate.js';
import { asyncHandler } from '../shared/utils/asyncHandler.js';

const router = Router();

/** Valida un cupón para un subtotal dado (accesible a invitados). */
router.post(
  '/validate',
  [
    body('code').isString().trim().notEmpty().withMessage('Código requerido'),
    body('subtotal').isFloat({ min: 0 }).withMessage('Subtotal inválido'),
  ],
  validate,
  asyncHandler(couponController.validate),
);

export default router;
