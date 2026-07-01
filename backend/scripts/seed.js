/**
 * Script de seed inicial de Firestore.
 *
 * Carga:
 *   • `categorias`     ← firebase/seed/categories.json (20 cat / 118 subcat)
 *   • `marcas`         ← una marca por defecto ("Genérica")
 *   • `configuracion`  ← documento `general` con parámetros base
 *
 * Es IDEMPOTENTE: usa `set` con doc IDs estables, así que se puede re-correr
 * sin duplicar. Requiere credenciales válidas (ver backend/.env).
 *
 * Uso:
 *   cd backend && npm run seed
 *   cd backend && npm run seed -- --demo     (además, productos de demo)
 */
import { readFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

import { db, FieldValue, Timestamp } from '../src/config/firebase.js';
import { COLLECTIONS } from '../src/shared/constants/orderStates.js';
import { logger } from '../src/shared/utils/logger.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SEED_DIR = resolve(__dirname, '../../firebase/seed');

/** Escribe en lotes respetando el límite de 500 operaciones por batch. */
async function commitInChunks(operations) {
  const CHUNK = 450;
  for (let i = 0; i < operations.length; i += CHUNK) {
    const batch = db.batch();
    for (const op of operations.slice(i, i + CHUNK)) op(batch);
    await batch.commit();
  }
}

async function seedCategories() {
  const file = resolve(SEED_DIR, 'categories.json');
  const { categories } = JSON.parse(readFileSync(file, 'utf8'));

  const ops = categories.map((cat) => (batch) => {
    const ref = db.collection(COLLECTIONS.CATEGORIES).doc(cat.id);
    batch.set(ref, {
      name: cat.name,
      slug: cat.slug,
      iconName: cat.iconName ?? null,
      imageUrl: cat.imageUrl ?? null,
      order: cat.order ?? 0,
      isActive: cat.isActive ?? true,
      isFeatured: cat.isFeatured ?? false,
      subcategories: (cat.subcategories ?? []).map((s, idx) => ({
        id: s.id,
        name: s.name,
        slug: s.slug,
        imageUrl: s.imageUrl ?? null,
        order: s.order ?? idx,
        isActive: s.isActive ?? true,
      })),
      updatedAt: FieldValue.serverTimestamp(),
    });
  });

  await commitInChunks(ops);
  const subs = categories.reduce((a, c) => a + (c.subcategories?.length ?? 0), 0);
  logger.info(`✅ categorias: ${categories.length} (${subs} subcategorías)`);
}

async function seedBrands() {
  await db.collection(COLLECTIONS.BRANDS).doc('genericbrand').set({
    name: 'Genérica',
    slug: 'genericbrand',
    logoUrl: null,
    isActive: true,
    updatedAt: FieldValue.serverTimestamp(),
  });
  logger.info('✅ marcas: 1 (Genérica)');
}

async function seedConfig() {
  await db.collection(COLLECTIONS.CONFIG).doc('general').set(
    {
      freeShippingThreshold: 80000,
      storePickupAddress: 'Av. Siempreviva 742, CABA',
      supportWhatsapp: '+5491100000000',
      homeBanners: [],
      maintenanceMode: false,
      updatedAt: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  logger.info('✅ configuracion/general');
}

/** Productos de demo (solo con flag --demo) para probar el catálogo. */
async function seedDemoProducts() {
  const now = Timestamp.now();
  const demo = [
    {
      id: 'demo-auriculares',
      sku: 'TC-AUR-0001',
      name: 'Auriculares Bluetooth TWS Pro',
      description: 'Auriculares inalámbricos con cancelación de ruido y estuche de carga.',
      categoryId: 'electronica',
      subcategoryId: 'audio',
      brandId: 'genericbrand',
      price: 24999,
      stock: 150,
      dimensions: { weightGrams: 120, widthCm: 6, heightCm: 3, lengthCm: 8 },
      images: [],
      isFeatured: true,
      isOnSale: true,
      discountPercentage: 20,
      isActive: true,
      searchKeywords: ['auriculares', 'bluetooth', 'tws', 'inalambricos', 'audio'],
      ratingAvg: 4.6,
      soldCount: 320,
    },
    {
      id: 'demo-remera',
      sku: 'TC-REM-0001',
      name: 'Remera Oversize Algodón',
      description: 'Remera unisex de algodón premium, corte oversize.',
      categoryId: 'moda-mujer',
      subcategoryId: 'remeras-tops',
      brandId: 'genericbrand',
      price: 12999,
      stock: 80,
      dimensions: { weightGrams: 200, widthCm: 30, heightCm: 2, lengthCm: 40 },
      images: [],
      isFeatured: false,
      isOnSale: false,
      discountPercentage: 0,
      isActive: true,
      searchKeywords: ['remera', 'oversize', 'algodon', 'unisex'],
      ratingAvg: 4.3,
      soldCount: 95,
    },
  ];

  const ops = demo.map((p) => (batch) => {
    const ref = db.collection(COLLECTIONS.PRODUCTS).doc(p.id);
    batch.set(ref, { ...p, createdAt: now, updatedAt: now });
  });
  await commitInChunks(ops);
  logger.info(`✅ productos demo: ${demo.length}`);
}

async function main() {
  const withDemo = process.argv.includes('--demo');
  logger.info('🌱 Iniciando seed de Firestore...');

  await seedCategories();
  await seedBrands();
  await seedConfig();
  if (withDemo) await seedDemoProducts();

  logger.info('🎉 Seed completado.');
  process.exit(0);
}

main().catch((err) => {
  logger.error({ err }, '❌ Seed falló');
  process.exit(1);
});
