# 🔥 Setup de Firebase — TodoClick (Fase 2)

Guía paso a paso. Las tareas marcadas con 👤 requieren **tu cuenta de Google**
(no las puedo hacer yo). El resto ya está codeado en el repo.

---

## 0. Requisitos

```bash
npm install -g firebase-tools          # Firebase CLI
dart pub global activate flutterfire_cli
firebase login                         # 👤 abre el navegador y autentica
```

---

## 1. 👤 Crear el proyecto Firebase

1. Andá a <https://console.firebase.google.com> → **Agregar proyecto**.
2. Nombre sugerido: `todoclick-prod` (si usás otro ID, actualizá
   `firebase/.firebaserc`, `firebase_options.dart` y `FIREBASE_PROJECT_ID`).
3. Activá **Google Analytics** (opcional, recomendado).

---

## 2. 👤 Habilitar los servicios

En la consola del proyecto:

### Authentication
- **Build → Authentication → Get started**.
- Habilitar proveedores:
  - **Email/Password** ✅
  - **Google** ✅ (definir email de soporte).
  - **Apple** ✅ (requiere cuenta Apple Developer; configurar Service ID y key —
    ver §6).

### Firestore Database
- **Build → Firestore Database → Create database**.
- Modo: **Production**. Ubicación: `southamerica-east1` (San Pablo, la más
  cercana a Argentina).

### Cloud Messaging
- **Engage → Messaging** ya queda disponible. Para iOS hay que subir la **APNs
  Auth Key** (ver §6).

---

## 3. 👤 Generar la configuración del cliente (FlutterFire)

```bash
cd app
flutterfire configure --project=todoclick-prod --platforms=android,ios,web
```

Esto **sobrescribe** `app/lib/firebase_options.dart` con los valores reales y
crea:
- `app/android/app/google-services.json`
- `app/ios/Runner/GoogleService-Info.plist`

> ⚠️ Estos archivos contienen identificadores del proyecto; están en
> `.gitignore`. La API key web de Firebase es pública por diseño, pero
> **restringila por dominio/app** en Google Cloud Console.

El bundle/application id por defecto es `com.todoclick.app` (ajustable).

---

## 4. Credenciales del backend (Admin SDK)

1. 👤 Consola → **⚙️ Configuración del proyecto → Cuentas de servicio →
   Generar nueva clave privada**. Descarga un JSON.
2. Guardalo en `backend/secrets/firebase-service-account.json`
   (la carpeta `secrets/` está en `.gitignore`).
3. En `backend/.env`:
   ```env
   GOOGLE_APPLICATION_CREDENTIALS=./secrets/firebase-service-account.json
   FIREBASE_PROJECT_ID=todoclick-prod
   ```
   En la nube (Cloud Run/Railway) usá `FIREBASE_SERVICE_ACCOUNT_JSON` con el
   JSON completo en una variable, en vez del archivo.

El SDK se inicializa en
[`backend/src/config/firebase.js`](../backend/src/config/firebase.js).

---

## 5. Deploy de reglas e índices + seed

```bash
# Reglas de seguridad e índices (desde la carpeta firebase/)
cd firebase
firebase deploy --only firestore:rules,firestore:indexes

# Datos iniciales (desde backend/, con credenciales ya configuradas)
cd ../backend
npm install
npm run seed                # categorías + marca por defecto + configuración
npm run seed -- --demo      # además, 2 productos de demo para probar

# Promover tu usuario a administrador (luego de registrarte en la app)
npm run set-admin -- <TU_UID>
```

> El `<TU_UID>` lo ves en Authentication → Users, o en el perfil dentro de la
> app una vez que te registres (Fase 4).

---

## 6. 👤 Notas por plataforma

### Android
- **SHA-1 / SHA-256:** para que funcione el login con Google, agregá las
  huellas en Consola → Configuración → tus apps Android:
  ```bash
  cd app/android && ./gradlew signingReport
  ```
- Re-descargá `google-services.json` si agregaste huellas.

### iOS / Apple Sign-In
- Cuenta **Apple Developer** activa.
- En Xcode: capability **Sign in with Apple** + **Push Notifications**.
- Subí la **APNs Authentication Key** (.p8) a Firebase → Cloud Messaging.
- Configurá el **Service ID** y la key de Apple en el proveedor Apple de Auth.

### Web
- Agregá tu dominio en Auth → Settings → **Authorized domains**.

---

## 7. Emuladores (desarrollo local, opcional)

`firebase.json` ya trae configurados los emuladores de Auth y Firestore:

```bash
cd firebase
firebase emulators:start
```

- Auth: `:9099` · Firestore: `:8081` · UI: `:4000`.
- Para que la app/backend apunten al emulador se agregan los `useEmulator(...)`
  en la Fase 3 (flag de entorno `USE_FIREBASE_EMULATOR`).

---

## ✅ Checklist Fase 2

- [ ] Proyecto `todoclick-prod` creado.
- [ ] Auth (Email, Google, Apple) habilitado.
- [ ] Firestore creado en `southamerica-east1`.
- [ ] `flutterfire configure` ejecutado (firebase_options.dart real).
- [ ] Service account descargada en `backend/secrets/`.
- [ ] Reglas + índices deployados.
- [ ] `npm run seed` ejecutado (categorías en Firestore).
- [ ] Tu usuario promovido a admin.
