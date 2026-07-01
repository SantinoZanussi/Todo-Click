import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  computeCouponDiscount,
  computeFinalPrice,
} from '../src/shared/utils/pricing.js';

test('computeFinalPrice: sin oferta devuelve el precio de lista', () => {
  assert.equal(computeFinalPrice({ price: 1000, isOnSale: false }), 1000);
});

test('computeFinalPrice: aplica el descuento de oferta', () => {
  assert.equal(
    computeFinalPrice({ price: 1000, isOnSale: true, discountPercentage: 20 }),
    800,
  );
});

test('computeFinalPrice: oferta con 0% no descuenta', () => {
  assert.equal(
    computeFinalPrice({ price: 1000, isOnSale: true, discountPercentage: 0 }),
    1000,
  );
});

test('computeCouponDiscount: porcentual', () => {
  assert.equal(computeCouponDiscount({ type: 'percentage', value: 10 }, 1000), 100);
});

test('computeCouponDiscount: porcentual respeta el tope', () => {
  assert.equal(
    computeCouponDiscount(
      { type: 'percentage', value: 50, maxDiscountAmount: 300 },
      1000,
    ),
    300,
  );
});

test('computeCouponDiscount: monto fijo no supera el subtotal', () => {
  assert.equal(
    computeCouponDiscount({ type: 'fixed_amount', value: 5000 }, 1000),
    1000,
  );
});

test('computeCouponDiscount: free_shipping no descuenta del subtotal', () => {
  assert.equal(
    computeCouponDiscount({ type: 'free_shipping', value: 0 }, 1000),
    0,
  );
});
