import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  estimateOptions,
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
