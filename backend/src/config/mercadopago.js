/**
 * Cliente de Mercado Pago (SDK v2).
 *
 * Expone instancias reutilizables de Preference (Checkout Pro) y Payment
 * (consulta de pagos en el webhook).
 */
import { MercadoPagoConfig, Payment, Preference } from 'mercadopago';

import { env } from './env.js';

const client = new MercadoPagoConfig({
  accessToken: env.mercadoPago.accessToken,
  options: { timeout: 8000 },
});

export const mpPreference = new Preference(client);
export const mpPayment = new Payment(client);
