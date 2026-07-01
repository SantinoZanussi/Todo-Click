# 🏗️ Arquitectura — TodoClick

## Visión general

TodoClick es un **monorepo** con tres deployables que comparten contratos:

```
todoclick/
├── app/        → Flutter (cliente + panel admin), Android · iOS · Web
├── backend/    → API Node.js + Express (lógica sensible)
├── firebase/   → reglas Firestore, índices, seeds
└── docs/       → documentación (este archivo y otros)
```

### Diagrama de alto nivel

```
┌─────────────────────────────────────────────────────────┐
│                 FLUTTER APP (cliente + admin)            │
│  Presentation → Domain → Data   (Clean Architecture)     │
└───────────┬───────────────────────────┬─────────────────┘
            │ Firebase SDK              │ HTTPS (REST / Dio)
            ▼                           ▼
┌────────────────────┐      ┌──────────────────────────────┐
│  FIREBASE          │◄─────┤  BACKEND Node + Express       │
│  Auth · Firestore  │Admin │  MP · Cloudinary · Correo Arg.│
│  Cloud Messaging   │ SDK  │  (controllers→services→repos) │
└────────────────────┘      └──────────────────────────────┘
```

**Regla de oro:** todo lo sensible (crear pagos, validar webhooks, firmar
uploads, escribir precios/stock/estados) pasa por el **backend**. El cliente
lee el catálogo directo de Firestore (rápido, con reglas de seguridad), pero
nunca escribe datos críticos ni maneja secretos.

---

## Clean Architecture en `app/`

Organización **por feature**; cada feature tiene tres capas con dependencias
que apuntan siempre hacia adentro (presentation → domain ← data):

```
lib/
├── core/                     # transversal a todas las features
│   ├── constants/            # AppConstants, FirestoreCollections, StorageKeys
│   ├── theme/                # AppColors (+ AppTheme en Fase 3)
│   ├── enums/                # OrderStatus, PaymentStatus, UserRole, ...
│   ├── error/                # Failure (dominio) + Exception (datos)
│   ├── usecase/              # contrato base UseCase<Type, Params>
│   ├── network/              # cliente HTTP (Dio) — Fase 3
│   ├── router/               # go_router — Fase 3
│   ├── di/                   # providers raíz de Riverpod — Fase 3
│   └── utils/                # formatters (moneda es_AR), validadores
│
├── features/<feature>/
│   ├── domain/               # PURO (sin Flutter/Firebase)
│   │   ├── entities/         # objetos de negocio (Equatable)
│   │   ├── repositories/     # interfaces (contratos)
│   │   └── usecases/         # interactors de negocio
│   ├── data/
│   │   ├── models/           # DTOs (extienden entidades) ↔ Firestore/JSON
│   │   ├── datasources/      # remoto (Firestore/API) y local (cache)
│   │   └── repositories/     # implementación de las interfaces de dominio
│   └── presentation/
│       ├── controllers/      # Notifiers de Riverpod (estado de UI)
│       ├── pages/            # pantallas
│       └── widgets/          # componentes de la feature
│
└── shared/widgets/           # componentes UI reutilizables entre features
```

### Features

`auth` · `catalog` · `cart` · `checkout` · `orders` · `favorites` ·
`promotions` · `shipping` · `notifications` · `profile` · `admin`

### Reglas de dependencia

1. **domain** no importa Flutter, Firebase ni paquetes de infraestructura.
   Solo Dart + `equatable` + `dartz`.
2. **data** depende de **domain** (implementa sus interfaces) y de la
   infraestructura (Firestore, Dio).
3. **presentation** depende de **domain** (usa entidades y use cases vía
   Riverpod). No conoce a **data** directamente.
4. El flujo de errores: `data` lanza `Exception` → el repositorio la traduce a
   `Failure` y devuelve `Either<Failure, T>` (`dartz`) → `presentation` muestra
   el mensaje. Nunca viajan excepciones crudas a la UI.

### Estado e inyección de dependencias

- **Riverpod** cumple ambos roles: gestión de estado (Notifiers) e inyección
  de dependencias (providers que arman repos/datasources/use cases).
- Se usa **code-generation** (`riverpod_generator`) para providers tipados.
- Los `Repository` se exponen como providers; los controllers de UI consumen
  use cases, no repos directamente.

---

## Arquitectura del `backend/`

Patrón en capas (Repository Pattern + servicios):

```
src/
├── index.js              # arranque del servidor (graceful shutdown)
├── app.js                # construcción de Express (middlewares + rutas)
├── config/               # env, firebase, mercadopago, cloudinary
├── routes/               # define endpoints y los conecta a controllers
├── controllers/          # parsean request/response, sin lógica de negocio
├── services/             # lógica de negocio (pagos, envíos, stock)
├── repositories/         # acceso a Firestore (Admin SDK)
├── middlewares/          # auth (verifica token/claim), validación, errores
└── shared/
    ├── constants/        # orderStates (espejo de los enums de Flutter)
    └── utils/            # logger (pino), ApiError
```

**Flujo de una request:**
`route → middleware (auth/validación) → controller → service → repository → Firestore`

- **controllers**: orquestan; no acceden a la DB directamente.
- **services**: reglas de negocio (validar cupón, recalcular total, crear
  preferencia MP, cotizar envío). Reutilizables y testeables.
- **repositories**: única capa que habla con Firestore.
- **middlewares**: `authMiddleware` verifica el ID token de Firebase y, para
  rutas admin, exige `role == 'admin'` en el claim.

---

## Sincronización de contratos frontend ↔ backend

Algunos valores son **contrato compartido** y deben permanecer idénticos entre
Dart y JS:

| Contrato | Flutter | Node |
|---|---|---|
| Estados de pedido/pago | `core/enums/*.dart` | `shared/constants/orderStates.js` |
| Nombres de colección | `FirestoreCollections` | `COLLECTIONS` |

Cualquier cambio en uno **debe replicarse** en el otro.
