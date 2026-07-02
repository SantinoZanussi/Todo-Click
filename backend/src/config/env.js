/**
 * Carga y valida las variables de entorno en un único lugar.
 *
 * El resto del código importa `env` desde acá en vez de leer `process.env`
 * directamente. Así centralizamos defaults y validaciones, y fallamos rápido
 * (fail-fast) si falta una variable crítica en producción.
 */
import 'dotenv/config';

/** Lee una variable requerida; lanza si falta (solo se evalúa al usarse). */
function required(key) {
  const value = process.env[key];
  if (!value) {
    throw new Error(`[env] Falta la variable de entorno requerida: ${key}`);
  }
  return value;
}

/** Lee una variable opcional con valor por defecto. */
function optional(key, fallback = '') {
  return process.env[key] ?? fallback;
}

export const env = {
  nodeEnv: optional('NODE_ENV', 'development'),
  isProd: optional('NODE_ENV', 'development') === 'production',
  port: Number(optional('PORT', '8080')),
  corsOrigins: optional('CORS_ORIGINS', '*')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean),

  firebase: {
    projectId: optional('FIREBASE_PROJECT_ID'),
    credentialsPath: optional('GOOGLE_APPLICATION_CREDENTIALS'),
    serviceAccountJson: optional('FIREBASE_SERVICE_ACCOUNT_JSON'),
  },

  mercadoPago: {
    accessToken: optional('MP_ACCESS_TOKEN'),
    webhookSecret: optional('MP_WEBHOOK_SECRET'),
    successUrl: optional('MP_SUCCESS_URL'),
    failureUrl: optional('MP_FAILURE_URL'),
    pendingUrl: optional('MP_PENDING_URL'),
    notificationUrl: optional('MP_NOTIFICATION_URL'),
  },

  cloudinary: {
    cloudName: optional('CLOUDINARY_CLOUD_NAME'),
    apiKey: optional('CLOUDINARY_API_KEY'),
    apiSecret: optional('CLOUDINARY_API_SECRET'),
    uploadFolder: optional('CLOUDINARY_UPLOAD_FOLDER', 'todoclick/products'),
  },

  shipping: {
    apiBase: optional('CORREO_ARGENTINO_API_BASE'),
    user: optional('CORREO_ARGENTINO_USER'),
    password: optional('CORREO_ARGENTINO_PASSWORD'),
    customerId: optional('CORREO_ARGENTINO_CUSTOMER_ID'),
    agreement: optional('CORREO_ARGENTINO_AGREEMENT'),
    originPostalCode: optional('SHIPPING_ORIGIN_POSTAL_CODE'),
    // Remitente (origen) para dar de alta envíos en MiCorreo (/shipping/import).
    sender: {
      name: optional('SHIPPING_ORIGIN_NAME'),
      phone: optional('SHIPPING_ORIGIN_PHONE'),
      cellPhone: optional('SHIPPING_ORIGIN_CELLPHONE'),
      email: optional('SHIPPING_ORIGIN_EMAIL'),
      streetName: optional('SHIPPING_ORIGIN_STREET_NAME'),
      streetNumber: optional('SHIPPING_ORIGIN_STREET_NUMBER'),
      floor: optional('SHIPPING_ORIGIN_FLOOR'),
      apartment: optional('SHIPPING_ORIGIN_APARTMENT'),
      city: optional('SHIPPING_ORIGIN_CITY'),
      provinceCode: optional('SHIPPING_ORIGIN_PROVINCE_CODE'),
      postalCode: optional('SHIPPING_ORIGIN_POSTAL_CODE'),
    },
  },

  // Helper para forzar la presencia de una variable en el punto de uso.
  require: required,
};
