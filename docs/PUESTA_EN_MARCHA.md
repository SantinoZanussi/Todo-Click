# 🚀 Puesta en marcha — Piloto Web (Mercado Pago sandbox)

Guía paso a paso de **todo lo que tenés que configurar vos** para dejar
TodoClick andando como piloto en **Web**, con pagos de **prueba**.

Marcado con 👤 = lo hacés vos (cuentas/credenciales). El código ya está listo.

> Orden recomendado: hacé los pasos de arriba hacia abajo. Tiempo estimado: ~1-2 hs.

---

## 0. Herramientas (una sola vez)

```bash
npm install -g firebase-tools          # Firebase CLI
dart pub global activate flutterfire_cli
# ngrok (para exponer el webhook de Mercado Pago en local):
#   Mac:  brew install ngrok
#   o descargá de https://ngrok.com/download  y creá una cuenta gratis
```

---

## 1. 👤 Firebase — crear proyecto y servicios

1. <https://console.firebase.google.com> → **Agregar proyecto** → nombre
   `todoclick-prod`.
   - Si usás otro ID, cambialo en `firebase/.firebaserc`, en
     `FIREBASE_PROJECT_ID` (backend) y volvé a correr `flutterfire configure`.
2. **Authentication → Get started → Sign-in method:**
   - Habilitá **Email/Password** ✅
   - Habilitá **Google** ✅ (elegí un email de soporte).
   - (Apple lo dejamos para cuando sumes iOS.)
3. **Firestore Database → Create database:**
   - Modo **Production**. Ubicación: **`southamerica-east1`** (San Pablo).
4. **Authentication → Settings → Authorized domains:** verificá que esté
   `localhost` (viene por defecto).

---

## 2. 👤 Generar la config del cliente (FlutterFire)

```bash
firebase login
cd app
flutterfire configure --project=todoclick-prod --platforms=web
```

Esto **sobrescribe** `app/lib/firebase_options.dart` con tus valores reales de
web. (No hace falta `google-services.json` para web.)

---

## 3. 👤 Service account para el backend

1. Consola → ⚙️ **Configuración del proyecto → Cuentas de servicio →
   Generar nueva clave privada** → se descarga un JSON.
2. Guardalo en `backend/secrets/firebase-service-account.json`
   (la carpeta `secrets/` ya está en `.gitignore`).

---

## 4. 👤 Cloudinary (imágenes de productos)

1. Creá una cuenta gratis en <https://cloudinary.com>.
2. En el **Dashboard** copiá: **Cloud name**, **API Key**, **API Secret**.

---

## 5. 👤 Mercado Pago (sandbox)

1. <https://www.mercadopago.com.ar/developers> → **Tus integraciones → Crear
   aplicación** → producto **Checkout Pro**.
2. En **Credenciales de prueba** copiá el **Access Token** (empieza con
   `TEST-...`).
3. **Webhook/Notificaciones:** lo configurás en el paso 8 (cuando tengas la URL
   de ngrok). Ahí MP te da una **clave secreta** para validar la firma.
   - Si no ponés secreto, el código igual funciona (omite la validación de
     firma); para el piloto está OK.

---

## 6. Deploy de reglas + índices y carga de datos

```bash
# Reglas de seguridad e índices de Firestore
cd firebase
firebase deploy --only firestore:rules,firestore:indexes

# Datos iniciales (categorías, marca, configuración + 2 productos de demo)
cd ../backend
npm install
npm run seed -- --demo
```

> ⚠️ El `seed` necesita el `.env` del paso 7 (al menos las credenciales de
> Firebase). Si lo corrés antes, completá primero el `.env`.

---

## 7. Backend — variables de entorno

`cp backend/.env.example backend/.env` y completá:

```env
NODE_ENV=development
PORT=8080
CORS_ORIGINS=*                         # para el piloto, * está bien

# Firebase (paso 3)
GOOGLE_APPLICATION_CREDENTIALS=./secrets/firebase-service-account.json
FIREBASE_PROJECT_ID=todoclick-prod

# Mercado Pago (paso 5) — credenciales de PRUEBA
MP_ACCESS_TOKEN=TEST-xxxxxxxx...
MP_WEBHOOK_SECRET=                     # lo completás en el paso 8 (opcional)
MP_NOTIFICATION_URL=                   # lo completás en el paso 8 (URL ngrok)
# back_urls opcionales: dejalas vacías para el piloto (la app usa polling)
MP_SUCCESS_URL=
MP_FAILURE_URL=
MP_PENDING_URL=

# Cloudinary (paso 4)
CLOUDINARY_CLOUD_NAME=...
CLOUDINARY_API_KEY=...
CLOUDINARY_API_SECRET=...
CLOUDINARY_UPLOAD_FOLDER=todoclick/products

# Correo Argentino: DEJAR VACÍO → usa estimación por zona/peso (no necesitás
# cuenta empresarial para el piloto).
```

---

## 8. Levantar el backend + exponer el webhook

```bash
# Terminal 1:
cd backend
npm run dev            # debería decir: 🚀 TodoClick API escuchando en :8080
# probá: http://localhost:8080/health

# Terminal 2 (túnel público para que Mercado Pago llegue al webhook):
ngrok http 8080
# copiá la URL https que te da, ej: https://ab12cd34.ngrok-free.app
```

Ahora:
1. Poné esa URL en `backend/.env`:
   `MP_NOTIFICATION_URL=https://ab12cd34.ngrok-free.app/api/payments/webhook`
2. 👤 En el panel de Mercado Pago → **Webhooks**, configurá esa misma URL y
   copiá la **clave secreta** → `MP_WEBHOOK_SECRET=...`
3. **Reiniciá** `npm run dev` para tomar los cambios.

---

## 9. Levantar la app (Web)

```bash
cd app
flutter pub get
flutter run -d chrome --web-port=5000 --dart-define=API_BASE_URL=http://localhost:8080
```

La app abre en `http://localhost:5000`. Como el backend corre en tu misma
máquina, `API_BASE_URL=http://localhost:8080` funciona. (El webhook va por
ngrok porque lo llama Mercado Pago desde afuera.)

---

## 10. Convertirte en administrador y cargar productos

1. En la app, **registrate** con email/contraseña (o Google).
2. Buscá tu **UID**: Firebase Console → Authentication → Users.
3. Asignate el rol admin:
   ```bash
   cd backend
   npm run set-admin -- TU_UID_ACA
   ```
4. **Cerrá sesión y volvé a entrar** → en *Perfil* ahora ves
   **"Panel de administración"**.
5. Desde el panel: cargá **categorías/marcas** si querés más, y **productos**
   reales (con imágenes → se suben a Cloudinary). Creá algún **cupón** para
   probar.

---

## 11. Probar el flujo completo 🎯

1. Navegá el catálogo → agregá productos al carrito.
2. **Checkout:** completá datos, **Calcular envío** (elegí una opción),
   aplicá un **cupón**.
3. **Continuar al pago** → se abre Checkout Pro de Mercado Pago.
4. Pagá con una **tarjeta de prueba** (ver abajo).
5. Volvé a la app → la pantalla de resultado consulta el estado; cuando el
   webhook confirma, ves **pago aprobado**, el pedido en **"Mis pedidos"** y la
   **notificación** en el centro de notificaciones.
6. Desde el panel admin podés **cambiar el estado** del pedido y **asignar un
   código de seguimiento**.

### 💳 Tarjetas de prueba de Mercado Pago (sandbox)

El **nombre del titular** define el resultado:

| Titular | Resultado |
|---|---|
| `APRO` | Pago aprobado |
| `OTHE` | Rechazado por error general |
| `CONT` | Pendiente |

Tarjeta de ejemplo: **Mastercard** `5031 7557 3453 0604`, venc. `11/30`,
CVV `123`. (Más en la doc de MP → "Tarjetas de prueba".)

---

## ✅ Checklist

- [ ] Firebase: proyecto + Auth (Email/Google) + Firestore (southamerica-east1)
- [ ] `flutterfire configure` (firebase_options.dart real)
- [ ] Service account en `backend/secrets/`
- [ ] Cuenta Cloudinary + credenciales
- [ ] Access Token de prueba de Mercado Pago
- [ ] `firebase deploy` (reglas + índices) + `npm run seed -- --demo`
- [ ] `backend/.env` completo
- [ ] `npm run dev` + `ngrok` + `MP_NOTIFICATION_URL` + reinicio
- [ ] `flutter run -d chrome` con `API_BASE_URL`
- [ ] `npm run set-admin -- <uid>` y re-login
- [ ] Probar compra end-to-end con tarjeta de test

---

## Qué queda para más adelante (NO bloquea el piloto)

- **Push en web:** requiere VAPID + service worker. La app tolera que falle; el
  **centro de notificaciones in-app sí funciona** (se guardan en Firestore).
- **Android:** `flutterfire configure --platforms=android` + huella **SHA-1** en
  Firebase (para Google sign-in) + re-descargar `google-services.json`.
- **iOS:** cuenta Apple Developer (APNs para push + Sign in with Apple).
- **Correo Argentino real:** credenciales empresariales (hoy anda con
  estimación por zona/peso).
- **Deploy del backend** (Cloud Run / Railway) para que el piloto sea accesible
  por otros sin tu compu ni ngrok.
- **Build/release de la app** y CI — lo manejás vos.
