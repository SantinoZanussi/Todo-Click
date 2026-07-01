# TodoClick — Backend (Node + Express)

API que concentra la lógica sensible: creación de preferencias de Mercado Pago
y webhooks, cotización/tracking de Correo Argentino, uploads firmados a
Cloudinary, gestión de custom claims y escritura segura en Firestore (Admin SDK).

## Requisitos

- Node.js `>= 20`

## Setup

```bash
cp .env.example .env     # completar credenciales reales
npm install
npm run dev              # arranca con --watch en http://localhost:8080
```

Healthcheck: `GET /health` → `{ "status": "ok" }`

## Scripts

| Script | Acción |
|---|---|
| `npm run dev` | Servidor con recarga (`node --watch`) |
| `npm start` | Servidor en producción |
| `npm run lint` | ESLint |
| `npm test` | Tests (node:test) |

## Estructura

```
src/
├── index.js          # arranque + graceful shutdown
├── app.js            # construcción de Express (middlewares + rutas)
├── config/           # env y (por fase) firebase, mercadopago, cloudinary
├── routes/           # endpoints
├── controllers/      # request/response
├── services/         # lógica de negocio
├── repositories/     # acceso a Firestore (Admin SDK)
├── middlewares/      # auth, validación, manejo de errores
└── shared/
    ├── constants/    # orderStates (espejo de los enums de Flutter)
    └── utils/        # logger (pino), ApiError
```

## Rutas por fase

| Fase | Prefijo | Descripción |
|---|---|---|
| 4 | `/api/auth` | Perfiles, asignación de claim admin |
| 5 | `/api/products`, `/api/categories`, `/api/brands` | Catálogo (apoyo admin) |
| 7 | `/api/admin/*` | Gestión y estadísticas |
| 8 | `/api/payments` | Preferencias MP + webhook |
| 9 | `/api/shipping` | Cotización Correo Argentino + tracking |
| 10 | `/api/notifications` | Envío de push (FCM) |

> ⚠️ El webhook de Mercado Pago usa el body **raw** para validar la firma; se
> monta con su propio parser antes del `express.json()` global.

## Deploy

Pensado para **Cloud Run** o **Railway** (contenedor Node). El webhook de MP
requiere una URL HTTPS pública (`MP_NOTIFICATION_URL`). Detalle en la Fase 12.
