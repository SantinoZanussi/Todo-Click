/**
 * Construcción de la aplicación Express (sin arrancar el servidor).
 *
 * Separar `app` de `index.js` permite testear la app con supertest sin abrir
 * un puerto real. Acá se monta el middleware base y se registran las rutas.
 * Cada fase irá agregando sus routers en la sección indicada.
 */
import cors from 'cors';
import express from 'express';
import helmet from 'helmet';
import { pinoHttp } from 'pino-http';

import { env } from './config/env.js';
import { errorHandler, notFoundHandler } from './middlewares/errorHandler.js';
import adminRoutes from './routes/admin.routes.js';
import authRoutes from './routes/auth.routes.js';
import couponRoutes from './routes/coupon.routes.js';
import paymentRoutes from './routes/payment.routes.js';
import shippingRoutes from './routes/shipping.routes.js';
import { logger } from './shared/utils/logger.js';

export function createApp() {
  const app = express();

  // Seguridad y utilidades base
  app.use(helmet());
  app.use(
    cors({
      // En desarrollo reflejamos cualquier origen (el puerto de Flutter web
      // varía). En producción, solo los orígenes configurados en CORS_ORIGINS.
      origin:
        !env.isProd || env.corsOrigins.includes('*') ? true : env.corsOrigins,
      credentials: true,
    }),
  );
  app.use(pinoHttp({ logger }));

  // El webhook de Mercado Pago valida su firma (`x-signature`) sobre el
  // `data.id` + headers, no sobre el cuerpo completo, así que el parser JSON
  // estándar es suficiente para toda la API.
  app.use(express.json({ limit: '1mb' }));
  app.use(express.urlencoded({ extended: true }));

  // Healthcheck (para Cloud Run / monitoreo)
  app.get('/health', (_req, res) => {
    res.json({ status: 'ok', service: 'todoclick-backend', ts: Date.now() });
  });

  // ───────────────────────────────────────────────────────────────────────
  // RUTAS DE LA API  (se completan por fase)
  //   Fase 4  → /api/auth         (perfiles, custom claims de admin) ✅
  //   Fase 5  → /api/products, /api/categories, /api/brands
  //   Fase 7  → /api/admin/*       (gestión, estadísticas)
  //   Fase 8  → /api/payments      (preferencias MP + webhook)
  //   Fase 9  → /api/shipping      (cotización Correo Argentino + tracking)
  //   Fase 10 → /api/notifications (envío de push vía FCM)
  app.use('/api/auth', authRoutes);
  app.use('/api/coupons', couponRoutes);
  app.use('/api/payments', paymentRoutes);
  app.use('/api/shipping', shippingRoutes);
  app.use('/api/admin', adminRoutes);
  // ───────────────────────────────────────────────────────────────────────

  // Manejo de errores (siempre al final)
  app.use(notFoundHandler);
  app.use(errorHandler);

  return app;
}
