/**
 * Genera tokens de búsqueda (minúsculas, sin duplicados) a partir de los
 * textos relevantes de un producto. Se guardan en `searchKeywords` para
 * habilitar la búsqueda por `array-contains` en Firestore.
 */
const DIACRITICS = /\p{Diacritic}/gu;

export function buildSearchKeywords(...texts) {
  const tokens = new Set();
  for (const text of texts) {
    if (!text) continue;
    String(text)
      .toLowerCase()
      .normalize('NFD')
      .replace(DIACRITICS, '') // quita acentos
      .split(/[^a-z0-9]+/)
      .filter((t) => t.length >= 2)
      .forEach((t) => tokens.add(t));
  }
  return [...tokens].slice(0, 40);
}
