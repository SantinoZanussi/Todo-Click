# 🧪 Testing — TodoClick

## App (Flutter)

```bash
cd app
flutter test            # corre toda la suite
flutter test --coverage # con cobertura (genera coverage/lcov.info)
```

Cobertura actual (lógica de negocio y componentes clave):

| Archivo | Qué cubre |
|---|---|
| `test/core/enums_test.dart` | `OrderStatus`/`PaymentStatus`/`UserRole`: `fromKey`, `isPaid`, `isFinal`, roles |
| `test/core/validators_test.dart` | email, password, teléfono AR, CP/CPA, números |
| `test/core/formatters_test.dart` | moneda ARS y porcentaje de descuento |
| `test/features/catalog/product_test.dart` | `finalPrice`, `savings`, `hasStock`, `mainImage` |
| `test/features/cart/cart_test.dart` | `Cart`/`CartItem`: subtotal, cantidades, `contains` |
| `test/features/cart/cart_controller_test.dart` | `CartController` con repo fake (agregar, stock máx, quitar, limpiar) |
| `test/features/promotions/coupon_test.dart` | `discountFor` (tope, mínimo, free shipping), `isValidAt` |
| `test/widgets/price_tag_test.dart` | widget `PriceTag` (con/sin descuento) |

> Patrón de test de providers: se usa `ProviderContainer` con overrides
> (`cartRepositoryProvider` con un fake en memoria y `authStateProvider` con un
> stream que no emite), evitando Firebase/red.

## Backend (Node)

```bash
cd backend
npm test                # node --test (descubre test/*.test.js)
```

Los tests cubren los **módulos puros** (sin Firebase/red), que es donde vive la
lógica crítica de dinero y logística:

| Archivo | Qué cubre |
|---|---|
| `test/pricing.test.js` | `computeFinalPrice` y `computeCouponDiscount` (oferta, tope, mínimo, free shipping) |
| `test/searchKeywords.test.js` | tokenización de búsqueda (minúsculas, sin acentos, sin duplicados) |
| `test/shippingEstimation.test.js` | cotización por zona/peso, 3 modalidades, retiro gratis |

> Para que la lógica fuera testeable sin credenciales, se extrajeron a módulos
> puros: `src/shared/utils/pricing.js` y `src/services/shipping/shippingEstimation.js`.
> Los servicios que dependen de Firebase (auth, webhook completo) se testean con
> emuladores/mocks en CI (Fase 12).

## Resultado

- **Flutter:** 46 tests ✅
- **Backend:** 15 tests ✅
