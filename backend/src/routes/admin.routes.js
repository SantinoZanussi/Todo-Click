/**
 * Rutas del panel de administración (`/api/admin`).
 *
 * Todo el router exige sesión válida + rol admin. Las lecturas de listados las
 * resuelve la app contra Firestore; acá viven solo las escrituras sensibles,
 * las estadísticas y la firma de uploads a Cloudinary.
 */
import { Router } from 'express';

import { adminController } from '../controllers/admin.controller.js';
import { requireAdmin, verifyFirebaseToken } from '../middlewares/auth.js';
import { asyncHandler } from '../shared/utils/asyncHandler.js';

const router = Router();

// Gate de seguridad para TODO el router.
router.use(verifyFirebaseToken, requireAdmin);

// Uploads + estadísticas
router.post('/uploads/signature', asyncHandler(adminController.uploadSignature));
router.get('/stats', asyncHandler(adminController.stats));

// Productos
router.post('/products', asyncHandler(adminController.createProduct));
router.put('/products/:id', asyncHandler(adminController.updateProduct));
router.delete('/products/:id', asyncHandler(adminController.deleteProduct));

// Categorías
router.post('/categories', asyncHandler(adminController.createCategory));
router.put('/categories/:id', asyncHandler(adminController.updateCategory));
router.delete('/categories/:id', asyncHandler(adminController.deleteCategory));

// Marcas
router.post('/brands', asyncHandler(adminController.createBrand));
router.put('/brands/:id', asyncHandler(adminController.updateBrand));
router.delete('/brands/:id', asyncHandler(adminController.deleteBrand));

// Cupones
router.post('/coupons', asyncHandler(adminController.createCoupon));
router.put('/coupons/:id', asyncHandler(adminController.updateCoupon));
router.delete('/coupons/:id', asyncHandler(adminController.deleteCoupon));

// Promociones
router.post('/promotions', asyncHandler(adminController.createPromotion));
router.put('/promotions/:id', asyncHandler(adminController.updatePromotion));
router.delete('/promotions/:id', asyncHandler(adminController.deletePromotion));

// Pedidos
router.patch('/orders/:id/status', asyncHandler(adminController.updateOrderStatus));
router.patch('/orders/:id/tracking', asyncHandler(adminController.setOrderTracking));
router.post('/orders/:id/ship', asyncHandler(adminController.shipOrder));

// Usuarios
router.patch('/users/:uid/role', asyncHandler(adminController.setUserRole));

// Notificaciones (broadcast de promos al tópico)
router.post('/notifications/broadcast', asyncHandler(adminController.broadcastPromo));

export default router;
