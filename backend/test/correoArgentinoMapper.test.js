import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  buildImportPayload,
  clampInt,
  humanizeEvent,
  mapAgencies,
  mapRates,
  parseCaDate,
  parseExpires,
  parseTrackingEvents,
  provinceCodeFor,
  splitStreet,
} from '../src/services/shipping/correoArgentinoMapper.js';

test('clampInt acota y redondea; no-número cae al mínimo', () => {
  assert.equal(clampInt(10.6, 1, 150), 11);
  assert.equal(clampInt(0, 1, 150), 1);
  assert.equal(clampInt(9999, 1, 150), 150);
  assert.equal(clampInt('abc', 1, 25000), 1);
});

test('mapRates: D → domicilio, S → sucursal, con costo y días', () => {
  const opts = mapRates([
    {
      deliveredType: 'D',
      productName: 'Correo Argentino Clasico',
      price: 498.06,
      deliveryTimeMin: '2',
      deliveryTimeMax: '5',
    },
    { deliveredType: 'S', price: 398.06, deliveryTimeMax: '4' },
  ]);
  assert.equal(opts.length, 2);
  assert.equal(opts[0].method, 'home_delivery');
  assert.equal(opts[0].cost, 498.06);
  assert.equal(opts[0].estimatedDays, 5);
  assert.equal(opts[0].carrier, 'Correo Argentino');
  assert.equal(opts[1].method, 'branch_pickup');
  assert.equal(opts[1].cost, 398.06);
});

test('mapRates: entrada inválida o sin precio → []/filtra', () => {
  assert.deepEqual(mapRates(null), []);
  assert.deepEqual(mapRates(undefined), []);
  assert.equal(mapRates([{ deliveredType: 'D' }]).length, 0);
});

test('parseCaDate: "DD-MM-YYYY HH:mm" → ISO -03:00', () => {
  const iso = parseCaDate('28-08-2024 10:33');
  assert.ok(iso.startsWith('2024-08-28T10:33'));
  assert.equal(parseCaDate(''), null);
  assert.equal(parseCaDate('no-fecha'), null);
});

test('parseExpires: "YYYY-MM-DD HH:mm:ss" → epoch ms', () => {
  const t = parseExpires('2022-04-26 21:16:20');
  assert.equal(typeof t, 'number');
  assert.ok(t > 0);
  assert.equal(parseExpires(''), null);
});

test('humanizeEvent: mapea conocidos y titula desconocidos', () => {
  assert.equal(humanizeEvent('ENTREGADO'), 'Entregado');
  assert.equal(humanizeEvent('PREIMPOSICION'), 'Registrado (pre-imposición)');
  assert.equal(humanizeEvent('algo raro'), 'Algo Raro');
  assert.equal(humanizeEvent(''), 'Actualización');
});

test('parseTrackingEvents: array con events → ordenado cronológico', () => {
  const events = parseTrackingEvents([
    {
      trackingNumber: '000500076393019A3G0C701',
      events: [
        { event: 'CADUCA', date: '09-12-2024 05:00', branch: 'CORREO ARGENTINO' },
        { event: 'PREIMPOSICION', date: '28-08-2024 10:33', branch: 'CA' },
      ],
    },
  ]);
  assert.equal(events.length, 2);
  // Ordenado ascendente por fecha: preimposición (ago) antes que caduca (dic).
  assert.equal(events[0].status, 'preimposicion');
  assert.equal(events[0].location, 'CA');
  assert.equal(events[1].status, 'caduca');
});

test('parseTrackingEvents: respuesta de error / vacía → []', () => {
  assert.deepEqual(parseTrackingEvents({ error: 'No existe', code: '0' }), []);
  assert.deepEqual(parseTrackingEvents({ events: [] }), []);
  assert.deepEqual(parseTrackingEvents(null), []);
});

test('provinceCodeFor: mapea nombres (con y sin acento) a código', () => {
  assert.equal(provinceCodeFor('Buenos Aires'), 'B');
  assert.equal(provinceCodeFor('Ciudad Autónoma de Buenos Aires'), 'C');
  assert.equal(provinceCodeFor('CABA'), 'C');
  assert.equal(provinceCodeFor('Córdoba'), 'X');
  assert.equal(provinceCodeFor('Tierra del Fuego, Antártida e Islas'), 'V');
  assert.equal(provinceCodeFor('Narnia'), null);
});

test('splitStreet: separa nombre y altura', () => {
  assert.deepEqual(splitStreet('Vicente Lopez 448'), {
    streetName: 'Vicente Lopez',
    streetNumber: '448',
  });
  assert.deepEqual(splitStreet('Av. San Martín 1234'), {
    streetName: 'Av. San Martín',
    streetNumber: '1234',
  });
  assert.deepEqual(splitStreet('Sin número'), {
    streetName: 'Sin número',
    streetNumber: 'S/N',
  });
});

test('mapAgencies: normaliza sucursales a forma simple', () => {
  const out = mapAgencies([
    {
      code: 'B0107',
      name: 'Monte Grande',
      phone: '(03401) 448396',
      services: { packageReception: true, pickupAvailability: true },
      location: {
        address: {
          streetName: 'Vicente Lopez',
          streetNumber: '448',
          city: 'Esteban Echeverria',
          province: 'Buenos Aires',
          postalCode: 'B1842ZAB',
        },
      },
      status: 'ACTIVE',
    },
  ]);
  assert.equal(out.length, 1);
  assert.equal(out[0].code, 'B0107');
  assert.equal(out[0].address, 'Vicente Lopez 448');
  assert.equal(out[0].services.pickupAvailability, true);
  assert.equal(mapAgencies(null).length, 0);
});

test('buildImportPayload: arma body de import a domicilio', () => {
  const order = {
    id: 'ord123',
    orderNumber: 'TC-2026-000001',
    total: 15999,
    shipping: {
      method: 'home_delivery',
      address: {
        firstName: 'Juan',
        lastName: 'Gonzalez',
        email: 'juan@mail.com',
        phone: '1165446544',
        province: 'Buenos Aires',
        city: 'La Plata',
        street: 'Calle 7 1234',
        apartment: '2B',
        postalCode: '1900',
      },
    },
  };
  const payload = buildImportPayload({
    order,
    sender: { name: 'TodoClick', provinceCode: 'C', postalCode: 'C1414' },
    pkg: { weightGrams: 2000, dimensions: { width: 20, height: 15, length: 30 } },
  });
  assert.equal(payload.extOrderId, 'ord123');
  assert.equal(payload.orderNumber, 'TC-2026-000001');
  assert.equal(payload.recipient.name, 'Juan Gonzalez');
  assert.equal(payload.recipient.email, 'juan@mail.com');
  assert.equal(payload.shipping.deliveryType, 'D');
  assert.equal(payload.shipping.agency, null);
  assert.equal(payload.shipping.address.streetName, 'Calle 7');
  assert.equal(payload.shipping.address.streetNumber, '1234');
  assert.equal(payload.shipping.address.provinceCode, 'B');
  assert.equal(payload.shipping.weight, 2000);
  assert.equal(payload.shipping.declaredValue, 15999);
  assert.equal(payload.shipping.height, 15);
});

test('buildImportPayload: envío a sucursal usa deliveryType S + agency', () => {
  const order = {
    id: 'o2',
    orderNumber: 'TC-2026-000002',
    subtotal: 5000,
    shipping: { method: 'branch_pickup', address: { province: 'Córdoba', street: 'Colón 100' } },
  };
  const payload = buildImportPayload({ order, agency: 'X0055', pkg: {} });
  assert.equal(payload.shipping.deliveryType, 'S');
  assert.equal(payload.shipping.agency, 'X0055');
  assert.equal(payload.shipping.address.provinceCode, 'X');
  assert.equal(payload.shipping.declaredValue, 5000);
});
