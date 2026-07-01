# 🛍️ TodoClick

**E-commerce estilo Shein/Temu para Argentina** — un marketplace de productos
variadísimos (moda, hogar, tecnología, belleza, mascotas y mucho más) con
catálogo, carrito, pagos con Mercado Pago, envíos con Correo Argentino, panel
de administración y notificaciones push.

> _"Todo lo que buscás, a un click."_

---

## 🧱 Stack

| Capa | Tecnología |
|---|---|
| **Frontend** | Flutter (Android · iOS · Web) · Riverpod · go_router |
| **Backend** | Node.js + Express |
| **Base de datos** | Firebase Firestore |
| **Auth** | Firebase Authentication (Email · Google · Apple · Invitado) |
| **Imágenes** | Cloudinary |
| **Pagos** | Mercado Pago Checkout Pro |
| **Logística** | Correo Argentino (vía interfaz `ShippingProvider`) |
| **Notificaciones** | Firebase Cloud Messaging |
| **Arquitectura** | Clean Architecture · Repository Pattern · DI (Riverpod) |

---

## 📁 Estructura del monorepo

```
todoclick/
├── app/        # Flutter — cliente + panel admin
│   └── lib/
│       ├── core/        # theme, enums, errores, constantes, router, DI
│       ├── features/    # auth, catalog, cart, checkout, orders, favorites,
│       │                #   promotions, shipping, notifications, profile, admin
│       └── shared/      # widgets reutilizables
├── backend/    # API Node + Express (MP, Cloudinary, Correo, Firebase Admin)
│   └── src/    # config, routes, controllers, services, repositories, middlewares
├── firebase/   # firestore.rules, firestore.indexes.json, seed/
└── docs/        # documentación del proyecto
```

---

## 📚 Documentación

| Documento | Contenido |
|---|---|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Clean Architecture, capas, flujo de datos, contratos compartidos |
| [docs/FIRESTORE_SCHEMA.md](docs/FIRESTORE_SCHEMA.md) | Las 11 colecciones: esquema, ejemplos, índices, seguridad |
| [docs/CATEGORIES.md](docs/CATEGORIES.md) | Árbol completo de categorías (estilo Shein) |
| [docs/DESIGN_SYSTEM.md](docs/DESIGN_SYSTEM.md) | Paleta del logo, tipografía, componentes |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Plan de las 12 fases y decisiones fijadas |

---

## 🗺️ Estado del desarrollo

✅ **Las 12 fases están completas** (arquitectura → deploy). Ver el detalle en
[ROADMAP](docs/ROADMAP.md). Próximo foco: pulido de UI/UX.

Guías operativas:
- **[docs/PUESTA_EN_MARCHA.md](docs/PUESTA_EN_MARCHA.md)** — correr el piloto en local, paso a paso.
- **[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)** — configurar Firebase.
- **[docs/DEPLOY.md](docs/DEPLOY.md)** — publicar backend + web a internet.
- **[docs/TESTING.md](docs/TESTING.md)** — cómo correr los tests.

---

## 🚀 Puesta en marcha (resumen — guía completa en [PUESTA_EN_MARCHA.md](docs/PUESTA_EN_MARCHA.md))

### Requisitos

- Flutter `>= 3.41` · Dart `>= 3.11`
- Node.js `>= 20`
- Firebase CLI (`npm i -g firebase-tools`) + FlutterFire CLI
- Cuentas: Firebase, Cloudinary, Mercado Pago (Correo Argentino es opcional)

### App (Flutter)

```bash
cd app
flutter pub get          # (Fase 3)
flutter run              # Android / iOS / Web
```

### Backend (Node)

```bash
cd backend
cp .env.example .env     # completar credenciales
npm install
npm run dev              # http://localhost:8080/health
```

### Firebase

```bash
cd firebase
firebase deploy --only firestore:rules,firestore:indexes   # (Fase 2)
```

---

## 🔐 Seguridad

- Toda escritura sensible (precios, stock, estados de pedido, cupones, pagos)
  pasa por el **backend** con Firebase Admin SDK.
- El rol **admin** se valida contra el *custom claim* del token, nunca contra
  un campo de Firestore.
- Las credenciales viven en variables de entorno; **nunca** se commitean.

---

## 👥 Roles

- **Invitado:** navega el catálogo y compra sin registrarse.
- **Cliente:** cuenta con favoritos, carrito sincronizado, historial y tracking.
- **Administrador:** panel de gestión dentro de la misma app.

---

_Proyecto privado — TodoClick © 2026._
