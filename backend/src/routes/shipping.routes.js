/**
 * Rutas de envíos (`/api/shipping`). Accesibles a invitados (cotizar antes de
 * registrarse).
 */
import { Router } from 'express';
import { body } from 'express-validator';

import { shippingController } from '../controllers/shipping.controller.js';
import { validate } from '../middlewares/validate.js';
import { asyncHandler } from '../shared/utils/asyncHandler.js';

const router = Router();

router.post(
  '/quote',
  [
    body('province').isString().trim().notEmpty().withMessage('Provincia requerida'),
    body('postalCode').isString().trim().notEmpty().withMessage('CP requerido'),
    body('items').isArray({ min: 1 }).withMessage('Carrito vacío'),
  ],
  validate,
  asyncHandler(shippingController.quote),
);

router.get('/track/:code', asyncHandler(shippingController.track));

export default router;
