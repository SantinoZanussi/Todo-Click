/**
 * Proveedor de logística: Correo Argentino (API MiCorreo).
 *
 * Implementa el contrato `ShippingProvider` ({ quote, track }). Si hay
 * credenciales configuradas usa la API REAL de MiCorreo; si no (o si la API
 * falla), cae a una ESTIMACIÓN determinística por zona + peso, para que el
 * checkout funcione en desarrollo sin cuenta empresarial.
 *
 * Flujo real (según el documento oficial):
 *   1) POST /token con Basic Auth (user:password) → JWT (se cachea).
 *   2) POST /rates con Bearer → cotización a domicilio (D) y sucursal (S).
 *   3) GET  /shipping/tracking con Bearer → historial de eventos.
 *
 * Para sumar Andreani u otro: crear `andreani.provider.js` con la misma forma
 * y elegir el provider en `shipping.service.js`.
 */
import axios from 'axios';

import { env } from '../../config/env.js';
import { logger } from '../../shared/utils/logger.js';
import {
  clampInt,
  mapAgencies,
  mapRates,
  parseExpires,
  parseTrackingEvents,
  provinceCodeFor,
} from './correoArgentinoMapper.js';
import { estimateOptions } from './shippingEstimation.js';

const TIMEOUT_MS = 8000;

/** `customerId` de MiCorreo (o el acuerdo legacy si aún no se migró). */
function customerId() {
  return env.shipping.customerId || env.shipping.agreement;
}

/** ¿Están todas las credenciales para hablar con la API real? */
function isConfigured() {
  const s = env.shipping;
  return Boolean(
    s.apiBase && s.user && s.password && customerId() && s.originPostalCode,
  );
}

// ─────────────────────────── Autenticación (JWT) ───────────────────────────
// Cacheamos el token para no pedir /token en cada request. El JWT trae su
// vencimiento; lo renovamos 60s antes (o ante un 401).
let tokenCache = null; // { token, expiresAt }

async function fetchToken() {
  let res;
  try {
    res = await axios.post(`${env.shipping.apiBase}/token`, null, {
      auth: { username: env.shipping.user, password: env.shipping.password },
      timeout: TIMEOUT_MS,
      // /token no lleva body. Axios pone por defecto en POST un Content-Type
      // `application/x-www-form-urlencoded` que la API de Correo rechaza (415);
      // con `null` se quita el header (como el `curl` del manual).
      headers: { 'Content-Type': null },
    });
  } catch (err) {
    logger.warn(
      { status: err.response?.status, data: err.response?.data },
      'Correo Argentino /token falló (revisá usuario/contraseña de la API).',
    );
    throw err;
  }
  const token = res.data?.token;
  if (!token) throw new Error('Respuesta de /token sin token');
  const expiresAt = parseExpires(res.data?.expires) ?? Date.now() + 5 * 60 * 1000;
  tokenCache = { token, expiresAt };
  return token;
}

async function getToken() {
  if (tokenCache && tokenCache.expiresAt - 60_000 > Date.now()) {
    return tokenCache.token;
  }
  return fetchToken();
}

/** Ejecuta un request autenticado; si el token expiró (401) reintenta 1 vez. */
async function authed(config) {
  const build = (token) => {
    const headers = {
      ...(config.headers || {}),
      Authorization: `Bearer ${token}`,
    };
    // Solo declaramos JSON cuando hay body: un GET sin cuerpo con Content-Type
    // puede ser rechazado (415) por la API de Correo.
    if (config.data != null && headers['Content-Type'] == null) {
      headers['Content-Type'] = 'application/json';
    }
    return { ...config, timeout: TIMEOUT_MS, headers };
  };
  try {
    return await axios(build(await getToken()));
  } catch (err) {
    if (err.response?.status === 401) {
      tokenCache = null;
      return axios(build(await fetchToken()));
    }
    throw err;
  }
}

// ───────────────────────────────── Provider ────────────────────────────────
export const correoArgentino = {
  async quote({ postalCode, province, weightKg, dimensions }) {
    if (isConfigured()) {
      try {
        const res = await authed({
          method: 'post',
          url: `${env.shipping.apiBase}/rates`,
          data: {
            customerId: customerId(),
            postalCodeOrigin: env.shipping.originPostalCode,
            postalCodeDestination: postalCode,
            // Sin `deliveredType` → cotiza domicilio (D) y sucursal (S) juntas.
            dimensions: {
              weight: clampInt(Math.round((weightKg || 0.1) * 1000), 1, 25000),
              height: clampInt(dimensions?.height ?? 10, 1, 150),
              width: clampInt(dimensions?.width ?? 20, 1, 150),
              length: clampInt(dimensions?.length ?? 30, 1, 150),
            },
          },
        });
        const options = mapRates(res.data?.rates);
        // La API no cubre el retiro en tienda propia: lo agregamos siempre.
        if (options.length) return [...options, storePickupOption()];
      } catch (err) {
        logger.warn(
          {
            err: err.message,
            status: err.response?.status,
            data: err.response?.data,
          },
          'Correo Argentino /rates falló; usando estimación.',
        );
      }
    }
    // Fallback: estimación por zona. Si el destino está en la misma provincia
    // que el origen (primera letra del CPA de origen = código de provincia),
    // se cotiza como envío local (más barato).
    const originCode = String(env.shipping.originPostalCode || '')
      .trim()
      .charAt(0)
      .toUpperCase();
    const local = Boolean(originCode) && originCode === provinceCodeFor(province);
    return estimateOptions({ province, weightKg, local });
  },

  async track(code) {
    if (isConfigured()) {
      try {
        const res = await authed({
          method: 'get',
          url: `${env.shipping.apiBase}/shipping/tracking`,
          data: { shippingId: code },
        });
        const events = parseTrackingEvents(res.data);
        if (events.length) return events;
      } catch (err) {
        logger.warn(
          {
            err: err.message,
            status: err.response?.status,
            data: err.response?.data,
          },
          'Correo Argentino /shipping/tracking falló; usando muestra.',
        );
      }
    }
    return estimateTracking(code);
  },

  /** Sucursales de una provincia (por código de una letra). Requiere API. */
  async agencies({ provinceCode, services } = {}) {
    if (!isConfigured() || !provinceCode) return [];
    try {
      const res = await authed({
        method: 'get',
        url: `${env.shipping.apiBase}/agencies`,
        params: {
          customerId: customerId(),
          provinceCode,
          ...(services ? { services } : {}),
        },
      });
      return mapAgencies(res.data);
    } catch (err) {
      logger.warn(
        {
          err: err.message,
          status: err.response?.status,
          data: err.response?.data,
        },
        'Correo Argentino /agencies falló; devuelvo lista vacía.',
      );
      return [];
    }
  },

  /**
   * Importa (da de alta) un envío en MiCorreo. `payload` ya viene armado por el
   * service (sin `customerId`, que se agrega acá). Devuelve `{ createdAt }`.
   * OJO: la API NO devuelve el número de tracking; el admin lo copia desde
   * MiCorreo y lo asigna con `PATCH /admin/orders/:id/tracking`.
   */
  async importShipping(payload) {
    if (!isConfigured()) {
      throw new Error(
        'Correo Argentino no está configurado (faltan credenciales).',
      );
    }
    const res = await authed({
      method: 'post',
      url: `${env.shipping.apiBase}/shipping/import`,
      data: { customerId: customerId(), ...payload },
    });
    return res.data;
  },
};

/** Opción propia de retiro en tienda (gratis) — la API de Correo no la cubre. */
function storePickupOption() {
  return {
    method: 'store_pickup',
    label: 'Retiro en tienda TodoClick',
    cost: 0,
    estimatedDays: 0,
    carrier: 'TodoClick',
  };
}

/** Eventos de muestra (fallback cuando no hay API o el código no existe). */
function estimateTracking() {
  const now = Date.now();
  const day = 86_400_000;
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
