# 🗺️ Roadmap — TodoClick

Desarrollo por fases. **Una fase por entrega**, con aprobación antes de avanzar.

| Fase | Nombre | Entregable principal | Estado |
|---|---|---|---|
| **1** | 🏗️ Arquitectura | Monorepo, design system, entidades de dominio, diseño Firestore (esquema + ejemplos + índices + reglas), categorías, README | ✅ **Hecho** |
| **2** | 🔥 Firebase | Admin SDK en backend, scripts de seed/admin, `firebase_options` (template), initializer, `.firebaserc`, guía de setup | ✅ **Código listo** · pendiente setup 👤 |
| **3** | 📱 Flutter base | `flutter pub get`, DI con Riverpod, go_router (shell + 5 tabs), `AppTheme` claro/oscuro, componentes base, main cableado. **Compila + build web ✅** | ✅ **Hecho** |
| **4** | 🔐 Autenticación | Email/pass, Google, Apple, invitado, recuperación, perfil; auth gate en router; middleware backend + `/api/auth/me`; interceptor de token en Dio. **Compila + build web ✅** | ✅ **Hecho** |
| **5** | 📦 Catálogo | Capa de datos Firestore (DTOs/datasource/repo), Home real, categorías (árbol Shein), búsqueda + filtros, detalle de producto, favoritos (local + sync). **Compila + build web ✅** | ✅ **Hecho** |
| **6** | 🛒 Carrito y Checkout | Carrito (local + sync Firestore, merge al loguear, badge en bottom nav), cupones (validación backend `/api/coupons/validate`), checkout (form de envío + resumen). **Compila + build web ✅** | ✅ **Hecho** |
| **7** | 🛠️ Panel admin | Backend admin (`/api/admin/*` con requireAdmin): CRUD productos/categorías/marcas/cupones/promos, pedidos, usuarios, stats, firma Cloudinary. App: dashboard + gestión completa, guard de rol, upload de imágenes. **Compila + build web ✅** | ✅ **Hecho** |
| **8** | 💳 Mercado Pago | Backend: crea pedido + preferencia (re-valida precios/stock/cupón), webhook (firma + actualiza estado + descuenta stock idempotente). App: checkout real → Checkout Pro, pantalla de resultado (polling), historial + detalle de pedido con timeline. **Compila + build web ✅** | ✅ **Hecho** |
| **9** | 🚚 Correo Argentino | Provider `ShippingProvider` (API real con fallback por zona/peso), cotización + 3 modalidades en el checkout (suma al total), tracking en detalle del pedido, admin asigna código. **Compila + build web ✅** | ✅ **Hecho** |
| **10** | 🔔 Notificaciones | Backend: push FCM en eventos de pedido (integrado al webhook + cambio de estado admin) + persistencia en `notificaciones` + broadcast de promos al tópico. App: permiso, token, foreground (local notif), tópico, centro de notificaciones + badge. **Compila + build web ✅** | ✅ **Hecho** |
| **11** | 🧪 Testing | Flutter: 46 tests (dominio, validadores, formatters, Product/Cart/Coupon, CartController con fake, widget PriceTag). Backend: 15 tests (pricing, searchKeywords, shipping). Refactor a módulos puros. Ver [TESTING.md](TESTING.md). **Todo verde ✅** | ✅ **Hecho** |
| **12** | 🚀 Deploy | `Dockerfile` + `.dockerignore` del backend (Railway/Cloud Run), Firebase Hosting para la web, guía paso a paso ([DEPLOY.md](DEPLOY.md)). (Builds de app nativa y CI los maneja el dueño.) | ✅ **Hecho** |

## Decisiones fijadas (Fase 0)

- **Logística:** Correo Argentino detrás de una interfaz `ShippingProvider`
  (Andreani u otro se enchufan sin reescribir).
- **Plataformas v1:** Android + iOS + Web (sin desktop por ahora).
- **Repo:** monorepo (`app/` + `backend/` + `firebase/` + `docs/`), git lo
  inicializa el dueño cuando quiera.
- **Hosting backend:** Express standalone (Cloud Run / Railway).
- **Estado/DI:** Riverpod con code-generation.
