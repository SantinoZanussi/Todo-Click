/**
 * Rutas de autenticación (`/api/auth`).
 */
import { Router } from 'express';

import { authController } from '../controllers/auth.controller.js';
import { verifyFirebaseToken } from '../middlewares/auth.js';
import { asyncHandler } from '../shared/utils/asyncHandler.js';

const router = Router();

/** Perfil del usuario autenticado (requiere token de Firebase). */
router.get('/me', verifyFirebaseToken, asyncHandler(authController.me));

export default router;
