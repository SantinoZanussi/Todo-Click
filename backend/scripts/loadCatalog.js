/**
 * Carga del catálogo real de TodoClick (reemplaza los productos de debug).
 *
 * Flujo (en orden):
 *   1. Vacía `productos`  → borra los productos de demo/debug.
 *   2. Vacía `carritos`   → limpia carritos de prueba (los 3 ítems que
 *      aparecían al iniciar sesión eran un carrito guardado, no código).
 *   3. Upsert de `marcas` reales (Apple, Samsung, JBL, ...).
 *   4. Carga los productos reales (precios exactos, sin descuentos).
 *   5. Poda subcategorías vacías dentro de las categorías que sobreviven.
 *   6. Elimina las categorías de nivel superior que quedan sin productos.
 *
 * Las imágenes se cargan aparte desde el panel admin (quedan en []).
 * Requiere credenciales válidas (backend/.env → GOOGLE_APPLICATION_CREDENTIALS).
 *
 * Uso:  cd backend && node scripts/loadCatalog.js
 */
import { db, FieldValue, Timestamp } from '../src/config/firebase.js';
import { COLLECTIONS } from '../src/shared/constants/orderStates.js';
import { logger } from '../src/shared/utils/logger.js';

/** Escribe operaciones en lotes de 450 (límite de 500 por batch). */
async function commitInChunks(operations) {
  const CHUNK = 450;
  for (let i = 0; i < operations.length; i += CHUNK) {
    const batch = db.batch();
    for (const op of operations.slice(i, i + CHUNK)) op(batch);
    await batch.commit();
  }
}

/** Borra todos los documentos de una colección (sin tocar subcolecciones). */
async function wipeCollection(name) {
  const snap = await db.collection(name).get();
  const ops = snap.docs.map((d) => (batch) => batch.delete(d.ref));
  await commitInChunks(ops);
  return snap.size;
}

/** Normaliza a slug/keyword: minúsculas, sin acentos, solo alfanumérico. */
function normalize(str) {
  return str
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim();
}

/** Genera keywords de búsqueda desde nombre + tipo + marca. */
function keywordsFor({ name, type, brandName }) {
  const raw = `${name} ${type} ${brandName}`;
  const tokens = normalize(raw).split(' ').filter((t) => t.length >= 2);
  return [...new Set(tokens)];
}

// ───────────────────────── Marcas ─────────────────────────

const BRANDS = {
  apple: 'Apple',
  motorola: 'Motorola',
  samsung: 'Samsung',
  lenovo: 'Lenovo',
  sony: 'Sony',
  jbl: 'JBL',
  logitech: 'Logitech',
  redragon: 'Redragon',
  sandisk: 'SanDisk',
  kingston: 'Kingston',
  xiaomi: 'Xiaomi',
  gopro: 'GoPro',
  canon: 'Canon',
  'tp-link': 'TP-Link',
  amazon: 'Amazon',
  google: 'Google',
  anker: 'Anker',
  lg: 'LG',
  microsoft: 'Microsoft',
};

// ───────────────────────── Productos ─────────────────────────
// d = [weightGrams, widthCm, heightCm, lengthCm]

const PRODUCTS = [
  { id: 'apple-iphone-16e-128gb', name: 'Apple iPhone 16e 128 GB', type: 'Smartphone', brand: 'apple', cat: 'celulares', sub: 'smartphones', price: 1134900, stock: 18, d: [180, 15, 5, 8], featured: true, desc: 'iPhone 16e con 128 GB de almacenamiento, chip de última generación y cámara avanzada.' },
  { id: 'motorola-edge-50-pro-512gb', name: 'Motorola Moto Edge 50 Pro 512 GB', type: 'Smartphone', brand: 'motorola', cat: 'celulares', sub: 'smartphones', price: 911999, stock: 22, d: [190, 16, 5, 8], desc: 'Moto Edge 50 Pro con 512 GB, pantalla pOLED curva y carga ultrarrápida.' },
  { id: 'samsung-galaxy-a06-128gb', name: 'Samsung Galaxy A06 128 GB', type: 'Smartphone', brand: 'samsung', cat: 'celulares', sub: 'smartphones', price: 271999, stock: 40, d: [190, 16, 5, 8], desc: 'Galaxy A06 con 128 GB, batería de gran duración y pantalla amplia.' },
  { id: 'motorola-moto-g24-power', name: 'Motorola Moto G24 Power', type: 'Smartphone', brand: 'motorola', cat: 'celulares', sub: 'smartphones', price: 269999, stock: 35, d: [200, 16, 5, 8], desc: 'Moto G24 Power con batería de larga autonomía y rendimiento equilibrado.' },
  { id: 'lenovo-loq-15-144hz', name: 'Lenovo LOQ 15.6” 144 Hz', type: 'Notebook gamer', brand: 'lenovo', cat: 'electronica', sub: 'computacion', price: 1440600, stock: 10, d: [2500, 42, 7, 30], featured: true, desc: 'Notebook gamer Lenovo LOQ 15.6” con pantalla de 144 Hz y gráfica dedicada.' },
  { id: 'sony-wh-ch520', name: 'Sony WH-CH520', type: 'Auriculares Bluetooth', brand: 'sony', cat: 'electronica', sub: 'audio', price: 89999, stock: 45, d: [200, 20, 8, 18], desc: 'Auriculares inalámbricos Sony WH-CH520 con hasta 50 horas de batería.' },
  { id: 'jbl-go-4', name: 'JBL Go 4', type: 'Parlante Bluetooth', brand: 'jbl', cat: 'electronica', sub: 'audio', price: 99900, stock: 60, d: [190, 12, 5, 9], desc: 'Parlante Bluetooth JBL Go 4 portátil, resistente al agua y polvo.' },
  { id: 'jbl-flip-7', name: 'JBL Flip 7', type: 'Parlante Bluetooth', brand: 'jbl', cat: 'electronica', sub: 'audio', price: 239999, stock: 30, d: [560, 20, 9, 9], featured: true, desc: 'Parlante JBL Flip 7 con sonido potente, resistencia IP68 y gran autonomía.' },
  { id: 'logitech-mx-master-3s', name: 'Logitech MX Master 3S', type: 'Mouse', brand: 'logitech', cat: 'electronica', sub: 'computacion', price: 149999, stock: 28, d: [140, 13, 5, 8], desc: 'Mouse inalámbrico Logitech MX Master 3S, silencioso y de alta precisión.' },
  { id: 'logitech-g502-hero', name: 'Logitech G502 HERO', type: 'Mouse gamer', brand: 'logitech', cat: 'electronica', sub: 'gaming', price: 79999, stock: 40, d: [120, 13, 5, 8], desc: 'Mouse gamer Logitech G502 HERO con sensor de 25K DPI y pesas ajustables.' },
  { id: 'logitech-k380', name: 'Logitech K380', type: 'Teclado Bluetooth', brand: 'logitech', cat: 'electronica', sub: 'computacion', price: 69999, stock: 35, d: [420, 28, 2, 12], desc: 'Teclado Bluetooth Logitech K380 multidispositivo, compacto y silencioso.' },
  { id: 'redragon-kumara-k552', name: 'Redragon Kumara K552', type: 'Teclado Mecánico', brand: 'redragon', cat: 'electronica', sub: 'gaming', price: 89999, stock: 32, d: [1050, 36, 4, 14], desc: 'Teclado mecánico Redragon Kumara K552 con retroiluminación e switches táctiles.' },
  { id: 'samsung-t7-shield-1tb', name: 'Samsung T7 Shield 1 TB', type: 'SSD Externo', brand: 'samsung', cat: 'electronica', sub: 'almacenamiento', price: 179999, stock: 25, d: [98, 12, 2, 6], desc: 'SSD externo Samsung T7 Shield 1 TB, resistente a golpes y agua, USB 3.2.' },
  { id: 'sandisk-extreme-1tb', name: 'SanDisk Extreme 1 TB', type: 'SSD Externo', brand: 'sandisk', cat: 'electronica', sub: 'almacenamiento', price: 169999, stock: 25, d: [120, 12, 2, 6], desc: 'SSD portátil SanDisk Extreme 1 TB con velocidades de hasta 1050 MB/s.' },
  { id: 'kingston-datatraveler-exodia-128gb', name: 'Kingston DataTraveler Exodia 128 GB', type: 'Pendrive', brand: 'kingston', cat: 'electronica', sub: 'almacenamiento', price: 24999, stock: 80, d: [15, 6, 1, 2], desc: 'Pendrive Kingston DataTraveler Exodia 128 GB USB 3.2 con tapa protectora.' },
  { id: 'xiaomi-mi-smart-band-9', name: 'Xiaomi Mi Smart Band 9', type: 'Smartband', brand: 'xiaomi', cat: 'electronica', sub: 'smartwatch', price: 89999, stock: 50, d: [30, 12, 3, 6], desc: 'Smartband Xiaomi Mi Smart Band 9 con pantalla AMOLED y monitoreo de salud.' },
  { id: 'samsung-galaxy-watch-7', name: 'Samsung Galaxy Watch 7', type: 'Smartwatch', brand: 'samsung', cat: 'electronica', sub: 'smartwatch', price: 549999, stock: 18, d: [120, 12, 9, 9], desc: 'Smartwatch Samsung Galaxy Watch 7 con sensores avanzados y GPS.' },
  { id: 'apple-watch-series-10-gps', name: 'Apple Watch Series 10 GPS', type: 'Smartwatch', brand: 'apple', cat: 'electronica', sub: 'smartwatch', price: 899999, stock: 15, d: [120, 12, 9, 9], featured: true, desc: 'Apple Watch Series 10 GPS con pantalla más grande y funciones de salud.' },
  { id: 'gopro-hero13-black', name: 'GoPro HERO13 Black', type: 'Cámara de Acción', brand: 'gopro', cat: 'electronica', sub: 'camaras', price: 899999, stock: 12, d: [160, 15, 8, 12], featured: true, desc: 'Cámara de acción GoPro HERO13 Black con video 5.3K y estabilización.' },
  { id: 'canon-eos-r50-kit', name: 'Canon EOS R50 Kit', type: 'Cámara Mirrorless', brand: 'canon', cat: 'electronica', sub: 'camaras', price: 1699999, stock: 8, d: [650, 25, 15, 18], featured: true, desc: 'Cámara mirrorless Canon EOS R50 con lente kit, ideal para foto y video 4K.' },
  { id: 'tp-link-archer-ax23', name: 'TP-Link Archer AX23', type: 'Router WiFi 6', brand: 'tp-link', cat: 'electronica', sub: 'computacion', price: 119999, stock: 30, d: [400, 26, 6, 18], desc: 'Router TP-Link Archer AX23 WiFi 6 de doble banda con cobertura amplia.' },
  { id: 'tp-link-deco-x20-2pack', name: 'TP-Link Deco X20 (2 Pack)', type: 'Sistema Mesh', brand: 'tp-link', cat: 'electronica', sub: 'computacion', price: 249999, stock: 20, d: [900, 30, 12, 20], desc: 'Sistema mesh TP-Link Deco X20 WiFi 6, pack de 2 unidades para toda la casa.' },
  { id: 'amazon-fire-tv-stick-4k', name: 'Amazon Fire TV Stick 4K', type: 'Streaming', brand: 'amazon', cat: 'electronica', sub: 'tv-video', price: 109999, stock: 55, d: [60, 14, 3, 9], desc: 'Amazon Fire TV Stick 4K con control por voz Alexa y streaming en 4K.' },
  { id: 'google-tv-streamer', name: 'Google TV Streamer', type: 'Streaming', brand: 'google', cat: 'electronica', sub: 'tv-video', price: 189999, stock: 30, d: [150, 15, 4, 11], desc: 'Google TV Streamer con 4K, Chromecast integrado y Google Assistant.' },
  { id: 'anker-powercore-20000', name: 'Anker PowerCore 20.000 mAh', type: 'Power Bank', brand: 'anker', cat: 'celulares', sub: 'powerbanks', price: 79999, stock: 45, d: [350, 16, 3, 8], desc: 'Power bank Anker PowerCore 20.000 mAh con carga rápida para dos dispositivos.' },
  { id: 'anker-nano-65w-gan', name: 'Cargador Anker Nano 65W GaN', type: 'Cargador', brand: 'anker', cat: 'celulares', sub: 'cargadores', price: 69999, stock: 50, d: [120, 9, 4, 6], desc: 'Cargador Anker Nano 65W con tecnología GaN, compacto y de carga rápida.' },
  { id: 'samsung-t350-24-fhd', name: 'Samsung T350 24” FHD', type: 'Monitor', brand: 'samsung', cat: 'electronica', sub: 'computacion', price: 229999, stock: 18, d: [3500, 60, 15, 40], desc: 'Monitor Samsung T350 24” Full HD con panel IPS y bordes ultrafinos.' },
  { id: 'lg-ultragear-27-180hz', name: 'LG UltraGear 27” 180 Hz', type: 'Monitor Gamer', brand: 'lg', cat: 'electronica', sub: 'gaming', price: 549999, stock: 12, d: [5200, 66, 20, 45], featured: true, desc: 'Monitor gamer LG UltraGear 27” con 180 Hz, 1 ms y compatibilidad G-Sync.' },
  { id: 'xbox-wireless-controller', name: 'Xbox Wireless Controller', type: 'Accesorio Gaming', brand: 'microsoft', cat: 'electronica', sub: 'gaming', price: 119999, stock: 30, d: [280, 18, 8, 12], desc: 'Joystick inalámbrico Xbox Wireless Controller compatible con consola y PC.' },
  { id: 'sony-dualsense-ps5', name: 'Sony DualSense PS5', type: 'Accesorio Gaming', brand: 'sony', cat: 'electronica', sub: 'gaming', price: 139999, stock: 28, d: [300, 18, 8, 12], featured: true, desc: 'Control Sony DualSense para PS5 con respuesta háptica y gatillos adaptativos.' },
];

// ───────────────────────── Pasos ─────────────────────────

async function loadBrands() {
  const ops = Object.entries(BRANDS).map(([slug, name]) => (batch) => {
    batch.set(db.collection(COLLECTIONS.BRANDS).doc(slug), {
      name,
      slug,
      logoUrl: null,
      isActive: true,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
  await commitInChunks(ops);
  logger.info(`✅ marcas: ${ops.length}`);
}

async function loadProducts() {
  const now = Timestamp.now();
  let sku = 1;
  const ops = PRODUCTS.map((p) => (batch) => {
    const [weightGrams, widthCm, heightCm, lengthCm] = p.d;
    batch.set(db.collection(COLLECTIONS.PRODUCTS).doc(p.id), {
      sku: `TC-${String(sku++).padStart(4, '0')}`,
      name: p.name,
      description: p.desc,
      categoryId: p.cat,
      subcategoryId: p.sub,
      brandId: p.brand,
      price: p.price,
      stock: p.stock,
      dimensions: { weightGrams, widthCm, heightCm, lengthCm },
      images: [],
      isFeatured: p.featured ?? false,
      isOnSale: false,
      discountPercentage: 0,
      isActive: true,
      searchKeywords: keywordsFor({
        name: p.name,
        type: p.type,
        brandName: BRANDS[p.brand],
      }),
      ratingAvg: 0,
      soldCount: 0,
      createdAt: now,
      updatedAt: now,
    });
  });
  await commitInChunks(ops);
  const feat = PRODUCTS.filter((p) => p.featured).length;
  logger.info(`✅ productos: ${ops.length} (${feat} destacados)`);
}

/** Poda subcategorías vacías y elimina categorías sin productos. */
async function pruneCategories() {
  const products = await db.collection(COLLECTIONS.PRODUCTS).get();
  const usedCats = new Set();
  const usedSubs = new Set(); // `${categoryId}/${subcategoryId}`
  for (const doc of products.docs) {
    const d = doc.data();
    usedCats.add(d.categoryId);
    usedSubs.add(`${d.categoryId}/${d.subcategoryId}`);
  }

  const cats = await db.collection(COLLECTIONS.CATEGORIES).get();
  const ops = [];
  let deleted = 0;
  let prunedSubs = 0;
  for (const doc of cats.docs) {
    if (!usedCats.has(doc.id)) {
      ops.push((batch) => batch.delete(doc.ref));
      deleted++;
      continue;
    }
    const subs = doc.data().subcategories ?? [];
    const kept = subs.filter((s) => usedSubs.has(`${doc.id}/${s.id}`));
    if (kept.length !== subs.length) {
      prunedSubs += subs.length - kept.length;
      ops.push((batch) =>
        batch.update(doc.ref, {
          subcategories: kept,
          updatedAt: FieldValue.serverTimestamp(),
        }),
      );
    }
  }
  await commitInChunks(ops);
  logger.info(
    `✅ categorías: ${deleted} eliminadas, ${cats.size - deleted} activas, ${prunedSubs} subcategorías podadas`,
  );
}

async function main() {
  logger.info('🚚 Cargando catálogo real de TodoClick...');

  const wipedProducts = await wipeCollection(COLLECTIONS.PRODUCTS);
  logger.info(`🧹 productos de debug borrados: ${wipedProducts}`);

  const wipedCarts = await wipeCollection(COLLECTIONS.CARTS);
  logger.info(`🧹 carritos de prueba borrados: ${wipedCarts}`);

  await loadBrands();
  await loadProducts();
  await pruneCategories();

  logger.info('🎉 Catálogo cargado. Las imágenes se suben desde el panel admin.');
  process.exit(0);
}

main().catch((err) => {
  logger.error({ err }, '❌ Carga de catálogo falló');
  process.exit(1);
});
