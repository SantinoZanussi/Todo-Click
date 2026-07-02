/**
 * Diagnóstico de la integración con Correo Argentino (API MiCorreo).
 *
 * Prueba, en orden y por separado, /token → /rates → /agencies, imprimiendo el
 * status HTTP y el cuerpo real de la respuesta. Sirve para saber EXACTAMENTE
 * en qué paso falla la autenticación/credenciales (sin adivinar por los logs).
 *
 * Uso:  npm run diag:correo   (desde /backend, con el .env cargado)
 */
import 'dotenv/config';
import axios from 'axios';

const base = process.env.CORREO_ARGENTINO_API_BASE;
const user = process.env.CORREO_ARGENTINO_USER;
const pass = process.env.CORREO_ARGENTINO_PASSWORD;
const customerId =
  process.env.CORREO_ARGENTINO_CUSTOMER_ID || process.env.CORREO_ARGENTINO_AGREEMENT;
const originCp = process.env.SHIPPING_ORIGIN_POSTAL_CODE;

const line = (s = '') => console.log(s);
const mask = (v) => (v ? `${String(v).slice(0, 2)}***(${String(v).length})` : '(vacío)');

function report(label, err) {
  line(`  ❌ ${label} FALLÓ`);
  line(`     status: ${err.response?.status ?? '(sin respuesta / red)'} ${err.response?.statusText ?? ''}`);
  line(`     body:   ${JSON.stringify(err.response?.data ?? err.message)}`);
}

async function main() {
  line('── Config ─────────────────────────────────');
  line(`  base:       ${base || '(vacío)'}`);
  line(`  user:       ${user || '(vacío)'}`);
  line(`  password:   ${mask(pass)}`);
  line(`  customerId: ${customerId || '(vacío)'}`);
  line(`  origen CP:  ${originCp || '(vacío)'}`);
  line('');

  if (!base || !user || !pass) {
    line('⚠️  Faltan base/usuario/contraseña en el .env. Cargalos y reintentá.');
    return;
  }

  // 1) TOKEN
  line('── 1) POST /token (Basic Auth) ────────────');
  let token;
  try {
    const res = await axios.post(`${base}/token`, null, {
      auth: { username: user, password: pass },
      headers: { 'Content-Type': null },
      timeout: 30000,
    });
    token = res.data?.token;
    line(`  ✅ status ${res.status} · token: ${token ? 'recibido' : 'NO vino token'} · expires: ${res.data?.expires ?? '-'}`);
  } catch (err) {
    report('/token', err);
    line('');
    if (!err.response) {
      line('👉 No hubo respuesta (timeout/red): NO es un problema de credenciales.');
      line('   La API TEST de Correo puede estar lenta o caída. Reintentá en un');
      line('   rato. Para probar conectividad cruda:');
      line(`   curl -m 30 -i -u "${user}:****" -X POST ${base}/token`);
    } else if (err.response.status === 401) {
      line('👉 401: el usuario/contraseña NO son válidos para la API (suelen ser');
      line('   credenciales de integración que hay que SOLICITAR a Correo,');
      line('   distintas del login de la web MiCorreo).');
    }
    return;
  }
  line('');

  const authHeaders = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

  // 2) RATES
  line('── 2) POST /rates (Bearer) ────────────────');
  try {
    const res = await axios.post(
      `${base}/rates`,
      {
        customerId,
        postalCodeOrigin: originCp,
        postalCodeDestination: '2000',
        dimensions: { weight: 500, height: 10, width: 15, length: 20 },
      },
      { headers: authHeaders, timeout: 30000 },
    );
    line(`  ✅ status ${res.status} · tarifas: ${JSON.stringify(res.data?.rates ?? res.data)}`);
  } catch (err) {
    report('/rates', err);
  }
  line('');

  // 3) AGENCIES
  line('── 3) GET /agencies (Bearer) ──────────────');
  try {
    const res = await axios.get(`${base}/agencies`, {
      headers: { Authorization: `Bearer ${token}` },
      params: { customerId, provinceCode: 'S' },
      timeout: 30000,
    });
    const count = Array.isArray(res.data) ? res.data.length : 0;
    line(`  ✅ status ${res.status} · sucursales: ${count}`);
  } catch (err) {
    report('/agencies', err);
  }
}

main().catch((e) => {
  line(`Error inesperado: ${e.message}`);
  process.exitCode = 1;
});
