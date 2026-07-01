/**
 * Proveedor de logística: Correo Argentino.
 *
 * Implementa el contrato `ShippingProvider` ({ quote, track }). Si hay
 * credenciales configuradas usa la API real (estructura preparada); si no,
 * cae a una ESTIMACIÓN determinística por zona + peso, para que el checkout
 * funcione en desarrollo sin cuenta empresarial.
 *
 * Para sumar Andreani u otro: crear `andreani.provider.js` con la misma forma
 * y elegir el provider en `shipping.service.js`.
 */
import axios from 'axios';

import { env } from '../../config/env.js';
import { logger } from '../../shared/utils/logger.js';
import { estimateOptions } from './shippingEstimation.js';

const CARRIER = 'Correo Argentino';

function estimateTracking(code) {
  // Eventos de muestra (la API real devuelve el historial verdadero).
  const now = Date.now();
  const day = 86400000;
  return [
    {
      status: 'admitido',
      description: 'Pieza admitida en sucursal de origen',
      date: new Date(now - 2 * day).toISOString(),
      location: 'CABA',
    },
    {
      status: 'en_transito',
      description: 'En tránsito hacia destino',
      date: new Date(now - day).toISOString(),
      location: 'Centro de distribución',
    },
    {
      status: 'en_reparto',
      description: 'En reparto',
      date: new Date(now).toISOString(),
      location: 'Sucursal destino',
    },
  ];
}

export const correoArgentino = {
  async quote({ postalCode, province, weightKg }) {
    if (env.shipping.user && env.shipping.password) {
      try {
        // TODO(prod): mapear a la API real de Correo Argentino (Mi Correo /
        // Paq.ar). Ejemplo de estructura:
        const res = await axios.post(
          `${env.shipping.apiBase}/rates`,
          {
            customerId: env.shipping.agreement,
            postalCodeOrigin: env.shipping.originPostalCode,
            postalCodeDestination: postalCode,
            dimensions: { weight: Math.round(weightKg * 1000) },
          },
          { auth: { username: env.shipping.user, password: env.shipping.password }, timeout: 8000 },
        );
        if (Array.isArray(res.data?.rates)) {
          return res.data.rates.map(mapRealRate);
        }
      } catch (err) {
        logger.warn({ err: err.message }, 'Correo Argentino API falló; usando estimación.');
      }
    }
    return estimateOptions({ province, weightKg });
  },

  async track(code) {
    if (env.shipping.user && env.shipping.password) {
      try {
        const res = await axios.get(`${env.shipping.apiBase}/tracking/${code}`, {
          auth: { username: env.shipping.user, password: env.shipping.password },
          timeout: 8000,
        });
        if (Array.isArray(res.data?.events)) return res.data.events;
      } catch (err) {
        logger.warn({ err: err.message }, 'Tracking CA falló; usando muestra.');
      }
    }
    return estimateTracking(code);
  },
};

/** Normaliza una tarifa real de la API a nuestra forma de opción. */
function mapRealRate(rate) {
  return {
    method: rate.deliveryType === 'D' ? 'home_delivery' : 'branch_pickup',
    label: rate.productName ?? 'Envío',
    cost: Number(rate.price) || 0,
    estimatedDays: Number(rate.deliveryTimeMax) || 5,
    carrier: CARRIER,
  };
}
