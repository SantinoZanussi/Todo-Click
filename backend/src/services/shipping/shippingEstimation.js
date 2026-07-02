/**
 * Estimación de costos de envío PURA (sin red ni credenciales), por zona
 * logística (derivada de la provincia) y peso. Es el fallback cuando no hay
 * API de Correo Argentino configurada, y es fácilmente testeable.
 */

const CARRIER = 'Correo Argentino';

// Zona logística por provincia (1 = más cerca/barato … 3 = más lejos/caro).
const ZONE_BY_PROVINCE = {
  'Ciudad Autónoma de Buenos Aires': 1,
  'Buenos Aires': 1,
  'Santa Fe': 2,
  'Córdoba': 2,
  'Entre Ríos': 2,
  'La Pampa': 2,
  Mendoza: 2,
  'San Luis': 2,
  Corrientes: 2,
  Misiones: 2,
  Chaco: 2,
  Formosa: 2,
  'Santiago del Estero': 2,
  Tucumán: 2,
  Catamarca: 3,
  'La Rioja': 3,
  'San Juan': 3,
  Jujuy: 3,
  Salta: 3,
  Neuquén: 3,
  'Río Negro': 3,
  Chubut: 3,
  'Santa Cruz': 3,
  'Tierra del Fuego': 3,
};

const ZONE_TARIFF = {
  0: { base: 2000, perKg: 350, days: 2 }, // local: misma provincia que el origen
  1: { base: 2500, perKg: 600, days: 3 },
  2: { base: 3500, perKg: 800, days: 5 },
  3: { base: 5000, perKg: 1100, days: 8 },
};

// Un paquete de correo no supera ~25kg; acotamos el peso facturable para que un
// carrito muy grande no dispare la estimación a valores absurdos.
const MAX_BILLABLE_KG = 25;

const round = (n) => Math.round(n / 10) * 10;

export function zoneFor(province) {
  return ZONE_BY_PROVINCE[province] ?? 2;
}

// Valores por defecto de un ítem sin dimensiones cargadas.
const DEFAULT_ITEM = {
  weightGrams: 500,
  widthCm: 20,
  heightCm: 10,
  lengthCm: 30,
};

function clampInt(value, min, max) {
  const n = Math.round(Number(value));
  if (!Number.isFinite(n)) return min;
  return Math.min(max, Math.max(min, n));
}

/**
 * Arma las dimensiones del paquete (peso + caja) a partir de los ítems del
 * carrito, para cotizar contra la API de Correo Argentino.
 *
 * Heurística simple y segura: peso = suma; ancho/largo = máximos entre ítems;
 * alto = suma (apilado). Todo acotado a los límites de MiCorreo (peso 1..25000g,
 * lados 1..150cm). `items` = `[{ weightGrams, widthCm, heightCm, lengthCm,
 * quantity }]` (cualquier campo faltante usa el default del ítem).
 */
export function packageFromItems(items = []) {
  let totalGrams = 0;
  let maxWidth = 0;
  let maxLength = 0;
  let sumHeight = 0;
  for (const raw of items) {
    const qty = Math.max(1, Number(raw?.quantity) || 1);
    const weightGrams = Number(raw?.weightGrams) || DEFAULT_ITEM.weightGrams;
    const widthCm = Number(raw?.widthCm) || DEFAULT_ITEM.widthCm;
    const heightCm = Number(raw?.heightCm) || DEFAULT_ITEM.heightCm;
    const lengthCm = Number(raw?.lengthCm) || DEFAULT_ITEM.lengthCm;
    totalGrams += weightGrams * qty;
    maxWidth = Math.max(maxWidth, widthCm);
    maxLength = Math.max(maxLength, lengthCm);
    sumHeight += heightCm * qty;
  }
  if (totalGrams <= 0) totalGrams = DEFAULT_ITEM.weightGrams;
  return {
    weightGrams: clampInt(totalGrams, 1, 25000),
    weightKg: Math.max(0.1, Math.round((totalGrams / 1000) * 100) / 100),
    dimensions: {
      width: clampInt(maxWidth || DEFAULT_ITEM.widthCm, 1, 150),
      height: clampInt(sumHeight || DEFAULT_ITEM.heightCm, 1, 150),
      length: clampInt(maxLength || DEFAULT_ITEM.lengthCm, 1, 150),
    },
  };
}

/**
 * Devuelve las 3 modalidades cotizadas para una provincia + peso.
 * `local` = el destino está en la misma provincia que el origen (más barato).
 */
export function estimateOptions({ province, weightKg, local = false }) {
  const tariff = ZONE_TARIFF[local ? 0 : zoneFor(province)];
  const billableKg = Math.min(Math.max(0.1, weightKg || 0.1), MAX_BILLABLE_KG);
  const homeCost = round(tariff.base + tariff.perKg * billableKg);
  const branchCost = round(homeCost * 0.85); // retiro en sucursal: más barato

  return [
    {
      method: 'home_delivery',
      label: 'Envío a domicilio',
      cost: homeCost,
      estimatedDays: tariff.days,
      carrier: CARRIER,
    },
    {
      method: 'branch_pickup',
      label: 'Retiro en sucursal de correo',
      cost: branchCost,
      estimatedDays: tariff.days + 1,
      carrier: CARRIER,
    },
    {
      method: 'store_pickup',
      label: 'Retiro en tienda TodoClick',
      cost: 0,
      estimatedDays: 0,
      carrier: 'TodoClick',
    },
  ];
}
