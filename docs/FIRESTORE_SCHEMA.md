# 🗄️ Esquema de Firestore — TodoClick

Diseño completo de las **11 colecciones**, con esquema de campos, ejemplos de
documentos, índices recomendados y notas de seguridad.

> **Convenciones**
> - IDs de documento: autogenerados salvo que se indique lo contrario.
> - Fechas: `Timestamp` de Firestore (no strings).
> - Dinero: `number` en ARS (pesos, con hasta 2 decimales).
> - Las claves de enums se persisten como **string** (ver `core/enums`).
> - Nombres de colección en **español** (definidos en `FirestoreCollections`).

---

## Índice de colecciones

| Colección | Doc ID | Lectura | Escritura |
|---|---|---|---|
| `usuarios` | `uid` (Auth) | dueño / admin | dueño (limitada) / backend |
| `productos` | auto | pública | backend (admin) |
| `categorias` | slug | pública | backend (admin) |
| `marcas` | slug | pública | backend (admin) |
| `pedidos` | auto | dueño / admin | backend (admin) |
| `favoritos` | `uid` | dueño | dueño |
| `carritos` | `uid` | dueño | dueño |
| `cupones` | code | admin | backend (admin) |
| `promociones` | auto | pública | backend (admin) |
| `notificaciones` | auto | dueño / admin | backend (admin) |
| `configuracion` | clave fija | pública | backend (admin) |

---

## 1. `usuarios/{uid}`

Perfil del cliente. El `uid` coincide con el de Firebase Auth. El `role` es
**informativo**; la fuente de verdad de permisos es el *custom claim* del token.

| Campo | Tipo | Notas |
|---|---|---|
| `uid` | string | = Auth uid |
| `email` | string | |
| `displayName` | string? | |
| `photoUrl` | string? | |
| `phone` | string? | |
| `role` | string | `client` \| `admin` (informativo) |
| `isEmailVerified` | bool | |
| `addresses` | array<map> | libreta de direcciones (ver `Address`) |
| `fcmTokens` | array<string> | tokens de dispositivos para push |
| `createdAt` | Timestamp | |
| `updatedAt` | Timestamp | |

```json
{
  "uid": "k3Jd9...",
  "email": "ana@example.com",
  "displayName": "Ana Pérez",
  "photoUrl": null,
  "phone": "+5491122334455",
  "role": "client",
  "isEmailVerified": true,
  "addresses": [
    {
      "id": "addr_1",
      "firstName": "Ana", "lastName": "Pérez",
      "email": "ana@example.com", "phone": "+5491122334455",
      "province": "Buenos Aires", "city": "La Plata",
      "street": "Calle 50 1234", "apartment": "3B",
      "postalCode": "B1900", "isDefault": true
    }
  ],
  "fcmTokens": ["fcm_abc123"],
  "createdAt": "2026-06-01T10:00:00Z",
  "updatedAt": "2026-06-20T12:30:00Z"
}
```

---

## 2. `productos/{productId}`

Catálogo. Incluye `searchKeywords` (array de tokens en minúsculas) para
soportar búsqueda por texto vía `array-contains` sin un motor externo.

| Campo | Tipo | Notas |
|---|---|---|
| `sku` | string | código interno único |
| `name` | string | |
| `description` | string | |
| `categoryId` | string | ref. `categorias` |
| `subcategoryId` | string | id de subcategoría |
| `brandId` | string | ref. `marcas` |
| `price` | number | precio de lista ARS |
| `stock` | number (int) | |
| `dimensions` | map | `{ weightGrams, widthCm, heightCm, lengthCm }` |
| `images` | array<string> | URLs Cloudinary (la 1ª es principal) |
| `isFeatured` | bool | destacado |
| `isOnSale` | bool | oferta |
| `discountPercentage` | number | 0-100 |
| `isActive` | bool | soft-delete |
| `searchKeywords` | array<string> | tokens para búsqueda |
| `ratingAvg` | number | promedio de reseñas (futuro) |
| `soldCount` | number | unidades vendidas (para "más vendidos") |
| `createdAt` / `updatedAt` | Timestamp | |

```json
{
  "sku": "TC-AUR-0001",
  "name": "Auriculares Bluetooth TWS Pro",
  "description": "Auriculares inalámbricos con cancelación de ruido...",
  "categoryId": "electronica",
  "subcategoryId": "audio",
  "brandId": "genericbrand",
  "price": 24999.0,
  "stock": 150,
  "dimensions": { "weightGrams": 120, "widthCm": 6, "heightCm": 3, "lengthCm": 8 },
  "images": [
    "https://res.cloudinary.com/todoclick/image/upload/v1/products/aur_1.jpg"
  ],
  "isFeatured": true,
  "isOnSale": true,
  "discountPercentage": 20,
  "isActive": true,
  "searchKeywords": ["auriculares", "bluetooth", "tws", "inalambricos", "audio"],
  "ratingAvg": 4.6,
  "soldCount": 320,
  "createdAt": "2026-06-10T09:00:00Z",
  "updatedAt": "2026-06-25T14:00:00Z"
}
```

---

## 3. `categorias/{slug}`

Doc ID = slug (p. ej. `electronica`). Subcategorías embebidas. Ver el set
inicial completo en [`firebase/seed/categories.json`](../firebase/seed/categories.json)
y [CATEGORIES.md](CATEGORIES.md).

```json
{
  "name": "Electrónica y Tecnología",
  "slug": "electronica",
  "iconName": "devices",
  "imageUrl": null,
  "order": 7,
  "isActive": true,
  "isFeatured": true,
  "subcategories": [
    { "id": "audio", "name": "Audio y Auriculares", "slug": "audio", "order": 0, "isActive": true }
  ]
}
```

---

## 4. `marcas/{slug}`

```json
{
  "name": "Genérica",
  "slug": "genericbrand",
  "logoUrl": null,
  "isActive": true
}
```

---

## 5. `pedidos/{orderId}`

Agregado central del checkout. Los ítems y la dirección son **snapshots**
inmutables. Lo crea y actualiza el backend (Admin SDK).

| Campo | Tipo | Notas |
|---|---|---|
| `orderNumber` | string | legible: `TC-2026-000123` |
| `userId` | string? | `null` si es invitado |
| `items` | array<map> | snapshot de `OrderItem` |
| `subtotal` | number | |
| `discount` | number | |
| `shippingCost` | number | |
| `total` | number | subtotal - discount + shippingCost |
| `couponCode` | string? | |
| `status` | string | enum `OrderStatus` |
| `shipping` | map | método, costo, dirección/sucursal, tracking |
| `payment` | map | estado MP, preferenceId, paymentId |
| `statusHistory` | array<map> | `{ status, at, note }` |
| `createdAt` / `updatedAt` | Timestamp | |

```json
{
  "orderNumber": "TC-2026-000123",
  "userId": "k3Jd9...",
  "items": [
    {
      "productId": "prod_1", "name": "Auriculares Bluetooth TWS Pro",
      "sku": "TC-AUR-0001",
      "imageUrl": "https://res.cloudinary.com/todoclick/.../aur_1.jpg",
      "unitPrice": 19999.2, "quantity": 2
    }
  ],
  "subtotal": 39998.4,
  "discount": 4000.0,
  "shippingCost": 3500.0,
  "total": 39498.4,
  "couponCode": "BIENVENIDO10",
  "status": "paid",
  "shipping": {
    "method": "home_delivery", "cost": 3500.0, "carrier": "Correo Argentino",
    "estimatedDays": 5, "trackingCode": "CA123456789AR",
    "address": {
      "firstName": "Ana", "lastName": "Pérez", "email": "ana@example.com",
      "phone": "+5491122334455", "province": "Buenos Aires", "city": "La Plata",
      "street": "Calle 50 1234", "postalCode": "B1900"
    },
    "branchId": null
  },
  "payment": {
    "status": "approved", "preferenceId": "1234-abcd",
    "paymentId": "111222333", "method": "visa_credit",
    "paidAt": "2026-06-28T16:05:00Z"
  },
  "statusHistory": [
    { "status": "pending", "at": "2026-06-28T16:00:00Z", "note": null },
    { "status": "paid", "at": "2026-06-28T16:05:00Z", "note": "Webhook MP" }
  ],
  "createdAt": "2026-06-28T16:00:00Z",
  "updatedAt": "2026-06-28T16:05:00Z"
}
```

---

## 6. `favoritos/{uid}`

Un doc por usuario con la lista de IDs (lectura simple, escritura desde la app).

```json
{ "productIds": ["prod_1", "prod_7", "prod_42"], "updatedAt": "2026-06-20T11:00:00Z" }
```

---

## 7. `carritos/{uid}`

Carrito sincronizado del usuario autenticado.

```json
{
  "items": [
    {
      "productId": "prod_1", "name": "Auriculares Bluetooth TWS Pro",
      "imageUrl": "https://res.cloudinary.com/.../aur_1.jpg",
      "sku": "TC-AUR-0001", "unitPrice": 19999.2, "quantity": 2, "maxStock": 150
    }
  ],
  "updatedAt": "2026-06-28T15:50:00Z"
}
```

---

## 8. `cupones/{code}`

Doc ID = código en MAYÚSCULAS. Nunca se listan al público.

```json
{
  "code": "BIENVENIDO10",
  "type": "percentage",
  "value": 10,
  "minPurchaseAmount": 15000,
  "maxDiscountAmount": 8000,
  "usageLimit": 1000,
  "usedCount": 134,
  "isActive": true,
  "validFrom": "2026-06-01T00:00:00Z",
  "validUntil": "2026-07-31T23:59:59Z",
  "description": "10% off para nuevos clientes"
}
```

---

## 9. `promociones/{promoId}`

Campañas/banners con descuento automático.

```json
{
  "title": "Hot Sale Tecnología",
  "subtitle": "Hasta 30% OFF",
  "bannerUrl": "https://res.cloudinary.com/todoclick/.../hotsale.jpg",
  "type": "percentage",
  "value": 30,
  "isActive": true,
  "validFrom": "2026-07-01T00:00:00Z",
  "validUntil": "2026-07-07T23:59:59Z",
  "targetCategoryIds": ["electronica", "celulares"],
  "targetProductIds": [],
  "order": 1
}
```

---

## 10. `notificaciones/{notificationId}`

Una por destinatario. El cliente solo puede marcar `read`.

```json
{
  "userId": "k3Jd9...",
  "type": "order_paid",
  "title": "¡Pago aprobado! 🎉",
  "body": "Tu pago del pedido TC-2026-000123 fue aprobado.",
  "data": { "orderId": "order_1", "orderNumber": "TC-2026-000123" },
  "read": false,
  "readAt": null,
  "createdAt": "2026-06-28T16:05:01Z"
}
```

---

## 11. `configuracion/{docId}`

Parámetros públicos editables sin redeploy. Doc IDs fijos (p. ej. `general`,
`home`, `shipping`).

```json
{
  "freeShippingThreshold": 80000,
  "storePickupAddress": "Av. Siempreviva 742, CABA",
  "supportWhatsapp": "+5491100000000",
  "homeBanners": ["promo_1", "promo_2"],
  "maintenanceMode": false
}
```

---

## Índices

Los índices compuestos están declarados en
[`firebase/firestore.indexes.json`](../firebase/firestore.indexes.json). Cubren:

- Catálogo por categoría / subcategoría / marca (+ orden por fecha).
- Destacados y ofertas.
- Filtro por rango de precios.
- Búsqueda por `searchKeywords` (`array-contains`).
- Historial de pedidos por usuario y por estado (admin).
- Notificaciones por usuario.

## Seguridad

Reglas completas en [`firebase/firestore.rules`](../firebase/firestore.rules).
Resumen: catálogo público de solo lectura; cada usuario accede solo a sus
datos; toda escritura sensible (precios, stock, estados, cupones) se hace desde
el backend con Admin SDK; el rol admin se valida contra el *custom claim*.
