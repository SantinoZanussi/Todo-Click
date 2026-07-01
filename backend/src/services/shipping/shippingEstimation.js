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
  1: { base: 2500, perKg: 600, days: 3 },
  2: { base: 3500, perKg: 800, days: 5 },
  3: { base: 5000, perKg: 1100, days: 8 },
};

const round = (n) => Math.round(n / 10) * 10;

export function zoneFor(province) {
  return ZONE_BY_PROVINCE[province] ?? 2;
}

/** Devuelve las 3 modalidades cotizadas para una provincia + peso. */
export function estimateOptions({ province, weightKg }) {
  const tariff = ZONE_TARIFF[zoneFor(province)];
  const homeCost = round(tariff.base + tariff.perKg * weightKg);
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
