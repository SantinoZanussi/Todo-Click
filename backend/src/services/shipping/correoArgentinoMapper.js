/**
 * Mapeos PUROS (sin red) de la API MiCorreo de Correo Argentino a las formas
 * internas de TodoClick. Se separan del provider para poder testearlos sin
 * tocar HTTP ni credenciales.
 *
 * Referencia: documento oficial "API MiCorreo" (endpoints /rates y
 * /shipping/tracking).
 */

export const CARRIER = 'Correo Argentino';

/** Acota un valor a un entero dentro de [min, max] (cae a `min` si no es número). */
export function clampInt(value, min, max) {
  const n = Math.round(Number(value));
  if (!Number.isFinite(n)) return min;
  return Math.min(max, Math.max(min, n));
}

/**
 * Convierte las tarifas de `/rates` (array `rates`) a nuestras opciones de
 * envío. `deliveredType` "D" → domicilio, "S" → sucursal.
 */
export function mapRates(rates) {
  if (!Array.isArray(rates)) return [];
  return rates
    .filter((r) => r && r.price != null)
    .map((r) => {
      const toBranch = r.deliveredType === 'S';
      return {
        method: toBranch ? 'branch_pickup' : 'home_delivery',
        label:
          r.productName ||
          (toBranch ? 'Retiro en sucursal de correo' : 'Envío a domicilio'),
        cost: Number(r.price) || 0,
        estimatedDays:
          Number(r.deliveryTimeMax) || Number(r.deliveryTimeMin) || 5,
        carrier: CARRIER,
      };
    });
}

const EVENT_LABELS = {
  PREIMPOSICION: 'Registrado (pre-imposición)',
  IMPOSICION: 'Admitido en origen',
  ADMITIDO: 'Admitido',
  ARRIBO: 'Arribó a sucursal',
  ARRIBADO: 'Arribó a sucursal',
  EN_TRANSITO: 'En tránsito',
  ENTRANSITO: 'En tránsito',
  EN_DISTRIBUCION: 'En distribución',
  EN_REPARTO: 'En reparto',
  ENTREGADO: 'Entregado',
  DEVOLUCION: 'En devolución',
  CADUCA: 'Caducado',
};

/** Texto legible para un código de evento de tracking. */
export function humanizeEvent(event) {
  if (!event) return 'Actualización';
  const key = String(event).toUpperCase().replace(/\s+/g, '_');
  if (EVENT_LABELS[key]) return EVENT_LABELS[key];
  return String(event)
    .toLowerCase()
    .replace(/(^|\s)\S/g, (c) => c.toUpperCase());
}

/**
 * Parsea la fecha de un evento de tracking ("DD-MM-YYYY HH:mm", hora AR -03:00)
 * a ISO 8601. Devuelve `null` si no se puede interpretar.
 */
export function parseCaDate(value) {
  if (!value) return null;
  const s = String(value).trim();
  const m = /^(\d{2})-(\d{2})-(\d{4})[ T](\d{2}):(\d{2})/.exec(s);
  if (m) {
    const [, d, mo, y, h, mi] = m;
    return `${y}-${mo}-${d}T${h}:${mi}:00-03:00`;
  }
  const t = Date.parse(s);
  return Number.isNaN(t) ? null : new Date(t).toISOString();
}

/**
 * Parsea el campo `expires` del token ("YYYY-MM-DD HH:mm:ss", hora AR) a epoch
 * en milisegundos. Devuelve `null` si no se puede interpretar.
 */
export function parseExpires(value) {
  if (!value) return null;
  const s = String(value).trim();
  const m = /^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2}):(\d{2})/.exec(s);
  if (m) {
    const [, y, mo, d, h, mi, se] = m;
    const t = Date.parse(`${y}-${mo}-${d}T${h}:${mi}:${se}-03:00`);
    return Number.isNaN(t) ? null : t;
  }
  const t = Date.parse(s);
  return Number.isNaN(t) ? null : t;
}

/**
 * Normaliza la respuesta de `/shipping/tracking` a nuestra lista de eventos
 * `{ status, description, date, location }`, ordenada cronológicamente.
 *
 * La API puede devolver un array `[{ events: [...] }]`, un objeto único con
 * `events`, o un objeto de error sin eventos.
 */
export function parseTrackingEvents(data) {
  const record = Array.isArray(data) ? data[0] : data;
  const events = record?.events;
  if (!Array.isArray(events)) return [];
  return events
    .map((e) => ({
      status: String(e.event || '').toLowerCase(),
      description: humanizeEvent(e.event),
      date: parseCaDate(e.date),
      location: e.branch || null,
    }))
    .filter((e) => e.date)
    .sort((a, b) => new Date(a.date) - new Date(b.date));
}

// ─────────────────────────── Provincias (códigos) ──────────────────────────
// Correo Argentino identifica las provincias por un código de una letra
// (ver tabla del documento). Mapeamos desde el NOMBRE que usa la app.
const PROVINCE_CODES = {
  salta: 'A',
  'buenos aires': 'B',
  'provincia de buenos aires': 'B',
  'ciudad autonoma de buenos aires': 'C',
  'ciudad de buenos aires': 'C',
  caba: 'C',
  'capital federal': 'C',
  'san luis': 'D',
  'entre rios': 'E',
  'la rioja': 'F',
  'santiago del estero': 'G',
  chaco: 'H',
  'san juan': 'J',
  catamarca: 'K',
  'la pampa': 'L',
  mendoza: 'M',
  misiones: 'N',
  formosa: 'P',
  neuquen: 'Q',
  'rio negro': 'R',
  'santa fe': 'S',
  tucuman: 'T',
  chubut: 'U',
  'tierra del fuego': 'V',
  corrientes: 'W',
  cordoba: 'X',
  jujuy: 'Y',
  'santa cruz': 'Z',
};

function normalize(value) {
  return String(value || '')
    .trim()
    .toLowerCase()
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '');
}

/** Código de provincia (una letra) a partir del nombre; `null` si no se conoce. */
export function provinceCodeFor(name) {
  const key = normalize(name);
  if (PROVINCE_CODES[key]) return PROVINCE_CODES[key];
  if (key.startsWith('tierra del fuego')) return 'V';
  return null;
}

/** Separa "Calle y altura" en `{ streetName, streetNumber }`. */
export function splitStreet(street) {
  const s = String(street || '').trim();
  const m = /^(.*?)[\s,]+(\d+\w*)$/.exec(s);
  if (m) return { streetName: m[1].trim(), streetNumber: m[2] };
  return { streetName: s || 'S/D', streetNumber: 'S/N' };
}

/** Normaliza la respuesta de `/agencies` a una forma simple para la app. */
export function mapAgencies(data) {
  if (!Array.isArray(data)) return [];
  return data.map((a) => {
    const addr = a.location?.address || {};
    return {
      code: a.code,
      name: a.name,
      address:
        [addr.streetName, addr.streetNumber].filter(Boolean).join(' ') || null,
      city: addr.city || addr.locality || null,
      province: addr.province || null,
      postalCode: addr.postalCode || null,
      phone: a.phone || null,
      services: {
        packageReception: Boolean(a.services?.packageReception),
        pickupAvailability: Boolean(a.services?.pickupAvailability),
      },
      hours: a.hours || null,
      status: a.status || null,
    };
  });
}

/**
 * Construye el body de `POST /shipping/import` a partir de un pedido de
 * TodoClick + la config del remitente + las dimensiones del paquete. NO incluye
 * `customerId` (lo agrega el provider). Puro y testeable.
 *
 * `order.shipping.address` = { firstName, lastName, email, phone, province,
 * city, street, apartment, postalCode }. `sender` viene de env (origen).
 * `pkg` = { weightGrams, dimensions:{ width, height, length } }.
 */
export function buildImportPayload({ order, sender = {}, agency = null, pkg = {} }) {
  const addr = order?.shipping?.address || {};
  const method = order?.shipping?.method || 'home_delivery';
  const deliveryType = method === 'branch_pickup' ? 'S' : 'D';
  const { streetName, streetNumber } = splitStreet(addr.street);
  const dims = pkg.dimensions || {};
  const recipientName =
    [addr.firstName, addr.lastName].filter(Boolean).join(' ').trim() || 'Cliente';

  return {
    extOrderId: String(order?.id ?? ''),
    orderNumber: String(order?.orderNumber ?? order?.id ?? ''),
    sender: {
      name: sender.name || null,
      phone: sender.phone || null,
      cellPhone: sender.cellPhone || null,
      email: sender.email || null,
      originAddress: {
        streetName: sender.streetName || null,
        streetNumber: sender.streetNumber || null,
        floor: sender.floor || null,
        apartment: sender.apartment || null,
        city: sender.city || null,
        provinceCode: sender.provinceCode || null,
        postalCode: sender.postalCode || null,
      },
    },
    recipient: {
      name: recipientName,
      phone: addr.phone || '',
      cellPhone: addr.phone || '',
      email: addr.email || '',
    },
    shipping: {
      deliveryType,
      productType: 'CP',
      agency: deliveryType === 'S' ? agency || order?.shipping?.branchId || null : null,
      address: {
        streetName,
        streetNumber,
        floor: '',
        apartment: addr.apartment || '',
        city: addr.city || '',
        provinceCode: provinceCodeFor(addr.province),
        postalCode: addr.postalCode || '',
      },
      weight: clampInt(pkg.weightGrams ?? 1000, 1, 25000),
      declaredValue: Number(order?.total) || Number(order?.subtotal) || 0,
      height: clampInt(dims.height ?? 10, 1, 150),
      length: clampInt(dims.length ?? 30, 1, 150),
      width: clampInt(dims.width ?? 20, 1, 150),
    },
  };
}
