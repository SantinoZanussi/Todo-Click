import assert from 'node:assert/strict';
import { test } from 'node:test';

import { buildSearchKeywords } from '../src/shared/utils/searchKeywords.js';

test('genera tokens en minúsculas y sin acentos', () => {
  const kw = buildSearchKeywords('Café Señor', 'Inalámbrico');
  assert.ok(kw.includes('cafe'));
  assert.ok(kw.includes('senor'));
  assert.ok(kw.includes('inalambrico'));
});

test('descarta tokens de 1 carácter y no duplica', () => {
  const kw = buildSearchKeywords('a Pro Pro');
  assert.ok(!kw.includes('a'));
  assert.equal(kw.filter((t) => t === 'pro').length, 1);
});

test('ignora valores nulos/indefinidos', () => {
  const kw = buildSearchKeywords(null, undefined, 'Bluetooth');
  assert.deepEqual(kw, ['bluetooth']);
});
