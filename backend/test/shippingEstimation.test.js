import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  estimateOptions,
  packageFromItems,
  zoneFor,
} from '../src/services/shipping/shippingEstimation.js';

test('devuelve las 3 modalidades en orden', () => {
  const opts = estimateOptions({ province: 'Córdoba', weightKg: 1 });
  assert.deepEqual(
    opts.map((o) => o.method),
    ['home_delivery', 'branch_pickup', 'store_pickup'],
  );
});

test('el retiro en tienda es gratis e inmediato', () => {
  const opts = estimateOptions({ province: 'Buenos Aires', weightKg: 2 });
  const store = opts.find((o) => o.method === 'store_pickup');
  assert.equal(store.cost, 0);
  assert.equal(store.estimatedDays, 0);
});

test('el retiro en sucursal es más barato que el envío a domicilio', () => {
  const opts = estimateOptions({ province: 'Mendoza', weightKg: 1 });
  const home = opts.find((o) => o.method === 'home_delivery');
  const branch = opts.find((o) => o.method === 'branch_pickup');
  assert.ok(branch.cost < home.cost);
});

test('zona 3 (Patagonia) cuesta más que zona 1 (CABA)', () => {
  const z1 = estimateOptions({
    province: 'Ciudad Autónoma de Buenos Aires',
    weightKg: 1,
  });
  const z3 = estimateOptions({ province: 'Santa Cruz', weightKg: 1 });
  const home1 = z1.find((o) => o.method === 'home_delivery').cost;
  const home3 = z3.find((o) => o.method === 'home_delivery').cost;
  assert.ok(home3 > home1);
});

test('provincia desconocida cae en zona 2', () => {
  assert.equal(zoneFor('Atlantis'), 2);
});

test('packageFromItems: suma peso, apila alto y toma máximos', () => {
  const pkg = packageFromItems([
    { weightGrams: 800, widthCm: 20, heightCm: 5, lengthCm: 30, quantity: 2 },
    { weightGrams: 400, widthCm: 25, heightCm: 8, lengthCm: 15, quantity: 1 },
  ]);
  assert.equal(pkg.weightGrams, 2000); // 800*2 + 400
  assert.equal(pkg.weightKg, 2);
  assert.equal(pkg.dimensions.width, 25); // máx
  assert.equal(pkg.dimensions.length, 30); // máx
  assert.equal(pkg.dimensions.height, 18); // 5*2 + 8
});

test('packageFromItems: sin dimensiones usa defaults y respeta límites', () => {
  const pkg = packageFromItems([{ quantity: 1 }]);
  assert.equal(pkg.weightGrams, 500);
  assert.ok(pkg.dimensions.width >= 1 && pkg.dimensions.width <= 150);
  assert.ok(pkg.dimensions.height >= 1 && pkg.dimensions.height <= 150);
});

test('packageFromItems: carrito vacío tiene peso mínimo válido', () => {
  const pkg = packageFromItems([]);
  assert.ok(pkg.weightGrams >= 1);
  assert.ok(pkg.weightKg >= 0.1);
});

test('packageFromItems: acota el alto apilado al máximo (150cm)', () => {
  const pkg = packageFromItems([
    { heightCm: 50, quantity: 10 }, // 500cm → clamp 150
  ]);
  assert.equal(pkg.dimensions.height, 150);
});

test('estimateOptions: envío local (misma provincia) es más barato', () => {
  const zonal = estimateOptions({ province: 'Santa Fe', weightKg: 3 });
  const local = estimateOptions({ province: 'Santa Fe', weightKg: 3, local: true });
  const zonalHome = zonal.find((o) => o.method === 'home_delivery').cost;
  const localHome = local.find((o) => o.method === 'home_delivery').cost;
  assert.ok(localHome < zonalHome);
});

test('estimateOptions: acota el peso facturable a 25kg', () => {
  const heavy = estimateOptions({ province: 'Córdoba', weightKg: 1000 });
  const capped = estimateOptions({ province: 'Córdoba', weightKg: 25 });
  const heavyHome = heavy.find((o) => o.method === 'home_delivery').cost;
  const cappedHome = capped.find((o) => o.method === 'home_delivery').cost;
  assert.equal(heavyHome, cappedHome);
});
