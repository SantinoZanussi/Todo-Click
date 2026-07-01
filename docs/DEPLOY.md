# 🚀 Deploy — Backend + Web a internet

**Objetivo:** sacar las 3 terminales de tu compu. El backend pasa a vivir en un
servidor con URL fija (reemplaza `npm run dev` + ngrok) y la web en Firebase
Hosting (una URL que abrís desde cualquier lado).

Vas a hacer 3 cosas, en este orden:

1. **Backend** → Railway (o Cloud Run) → te da una URL, ej: `https://todoclick-backend.up.railway.app`
2. **Web** → Firebase Hosting → te da una URL, ej: `https://todo-click-4aa1e.web.app`
3. **Conectar las dos** (CORS + webhook de Mercado Pago).

> No hace falta subir el repo a GitHub para deployar: los comandos CLI de abajo
> funcionan desde tu carpeta local. (Pushear a GitHub igual es recomendable para
> tener versionado.)

---

## Parte 1 — Backend

### Opción A: Railway (la más simple) ⭐

```bash
npm install -g @railway/cli
railway login                 # abre el navegador
cd backend
railway init                  # crea el proyecto (elegí un nombre)
railway up                    # sube y buildea usando el Dockerfile
```

Después, en el **dashboard de Railway** (railway.app):

1. **Variables** → cargá estas (son las mismas del `.env`, con UNA diferencia
   importante en Firebase):

   | Variable | Valor |
   |---|---|
   | `NODE_ENV` | `production` |
   | `FIREBASE_PROJECT_ID` | `todo-click-4aa1e` |
   | `FIREBASE_SERVICE_ACCOUNT_JSON` | **pegá el contenido COMPLETO** del `firebase-service-account.json` |
   | `MP_ACCESS_TOKEN` | tu token (`TEST-...` para piloto) |
   | `MP_WEBHOOK_SECRET` | el secreto del webhook de MP |
   | `CLOUDINARY_CLOUD_NAME` / `CLOUDINARY_API_KEY` / `CLOUDINARY_API_SECRET` | los tuyos |
   | `CLOUDINARY_UPLOAD_FOLDER` | `todoclick/products` |
   | `CORS_ORIGINS` | lo completás en la **Parte 3** (por ahora poné `*`) |
   | `MP_NOTIFICATION_URL` | lo completás abajo, cuando tengas la URL |

   > 🔑 En la nube NO se usa el archivo de credenciales: se pega el JSON en
   > `FIREBASE_SERVICE_ACCOUNT_JSON`. **No** pongas `GOOGLE_APPLICATION_CREDENTIALS`.
   > El código ya soporta las dos formas.

2. **Settings → Networking → Generate Domain** → te da la URL pública del
   backend. Copiala.
3. Volvé a **Variables** y poné
   `MP_NOTIFICATION_URL=https://TU-BACKEND.up.railway.app/api/payments/webhook`.
   Railway redeploya solo.
4. Probá: abrí `https://TU-BACKEND.up.railway.app/health` → debe responder
   `{"status":"ok"}`.

### Opción B: Google Cloud Run

```bash
# Requiere gcloud CLI y un proyecto de GCP (puede ser el mismo de Firebase).
cd backend
gcloud run deploy todoclick-backend \
  --source . \
  --region southamerica-east1 \
  --allow-unauthenticated \
  --set-env-vars NODE_ENV=production,FIREBASE_PROJECT_ID=todo-click-4aa1e,MP_ACCESS_TOKEN=TEST-...,CLOUDINARY_CLOUD_NAME=...,CLOUDINARY_API_KEY=...,CLOUDINARY_API_SECRET=...
# El JSON de Firebase conviene cargarlo como secreto:
#   gcloud secrets create firebase-sa --data-file=secrets/firebase-service-account.json
#   y montarlo como env var FIREBASE_SERVICE_ACCOUNT_JSON.
```

Cloud Run también te da una URL pública `https://...run.app`.

---

## Parte 2 — Web (Firebase Hosting)

La web necesita saber la URL del backend **al momento de compilar** (se inyecta
con `--dart-define`).

```bash
cd app
flutter build web --release --dart-define=API_BASE_URL=https://TU-BACKEND.up.railway.app

cd ../firebase
firebase deploy --only hosting
```

Al terminar te da la URL de la web, ej: `https://todo-click-4aa1e.web.app`.

> Firebase Hosting ya autoriza automáticamente los dominios `*.web.app` y
> `*.firebaseapp.com` para el login. Si más adelante ponés un dominio propio,
> agregalo en Authentication → Settings → Authorized domains.

---

## Parte 3 — Conectar backend ↔ web

1. **CORS del backend:** en Railway (o Cloud Run) actualizá
   `CORS_ORIGINS=https://todo-click-4aa1e.web.app,https://todo-click-4aa1e.firebaseapp.com`
   (en producción el backend solo acepta estos orígenes).
2. **Webhook de Mercado Pago:** en el panel de MP → Webhooks, cambiá la URL a
   `https://TU-BACKEND.up.railway.app/api/payments/webhook` (la de ngrok ya no
   se usa).

Listo: entrás a `https://todo-click-4aa1e.web.app` desde cualquier PC/celular y
la app funciona sola. 🎉

---

## ¿Cómo actualizo después de un cambio?

- **Cambié el backend** → `cd backend && railway up` (o `gcloud run deploy --source .`).
- **Cambié la app** → `cd app && flutter build web --release --dart-define=API_BASE_URL=<backend>` y `cd ../firebase && firebase deploy --only hosting`.
- **Cambié reglas/índices de Firestore** → `cd firebase && firebase deploy --only firestore`.

---

## ✅ Checklist

- [ ] Backend deployado (Railway/Cloud Run) y `/health` responde
- [ ] Variables de entorno cargadas (con `FIREBASE_SERVICE_ACCOUNT_JSON`)
- [ ] `MP_NOTIFICATION_URL` apunta al backend deployado
- [ ] Web buildeada con `API_BASE_URL` = URL del backend
- [ ] `firebase deploy --only hosting` hecho
- [ ] `CORS_ORIGINS` = dominio de la web
- [ ] Webhook de MP actualizado a la URL del backend
- [ ] Probado el flujo completo desde la URL pública

## Notas

- **Migrar de piloto a producción real:** cambiá el `MP_ACCESS_TOKEN` a las
  credenciales de producción (`APP_USR-...`) cuando quieras cobrar de verdad.
- **Costos:** Railway y Cloud Run tienen capa gratuita generosa; Firebase
  Hosting y Firestore (Spark) también. Para un piloto no deberías pagar nada.
