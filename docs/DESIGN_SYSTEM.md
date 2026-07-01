# 🎨 Design System — TodoClick

Identidad visual derivada del **logo**: una bolsa de compras multicolor + el
cursor "click". Moderno, colorido y con personalidad (inspiración: Mercado
Libre, Shein, Temu, Apple), evitando el minimalismo plano.

> La **implementación** en Flutter (`ThemeData`, `ColorScheme`, tipografía y
> componentes) se construye en la **Fase 3**. Este documento es la
> especificación; los tokens de color ya viven en
> [`app/lib/core/theme/app_colors.dart`](../app/lib/core/theme/app_colors.dart).

---

## Paleta de marca

| Token | Hex | Rol |
|---|---|---|
| `navy` | `#0B1B3A` | Texto fuerte, AppBar, marca "Todo" |
| `violet` | `#6C2BD9` | **Primario** — botones y acentos |
| `teal` | `#1FBFB8` | Secundario |
| `coral` | `#F4435B` | Ofertas, descuentos, error |
| `yellow` | `#F9B233` | Destacados, badges, CTA secundario |
| `royalBlue` | `#2F6BFF` | Links, acciones informativas |

### Semánticos

| Token | Hex |
|---|---|
| `success` | `#1FA971` |
| `warning` | `#F9B233` |
| `error` | `#F4435B` |
| `info` | `#2F6BFF` |

### Neutros

| Token | Hex | Uso |
|---|---|---|
| `ink` | `#101524` | Texto principal |
| `slate` | `#5B6478` | Texto secundario |
| `muted` | `#9AA1B1` | Hints / deshabilitado |
| `border` | `#E4E7EE` | Bordes / divisores |
| `surface` | `#FFFFFF` | Tarjetas |
| `background` | `#F6F7FB` | Fondo de pantalla |

### Gradientes

- **brandGradient**: `violet → royalBlue` (splash, CTA destacados, headers).
- **saleGradient**: `coral → yellow` (banners de oferta, badges "OFERTA").

---

## Tipografía

- **Familia:** `Inter` (texto) — geométrica, legible, moderna. Se agrega como
  asset/fuente en la Fase 3. Fallback: system font.
- **Escala (Material 3):**

| Estilo | Tamaño | Peso | Uso |
|---|---|---|---|
| displayLarge | 32 | 700 | Títulos hero |
| headlineMedium | 24 | 700 | Títulos de sección |
| titleLarge | 20 | 600 | Títulos de tarjeta / AppBar |
| bodyLarge | 16 | 400 | Texto base |
| bodyMedium | 14 | 400 | Texto secundario |
| labelLarge | 14 | 600 | Botones |
| labelSmall | 11 | 500 | Badges / captions |

Precios: `titleLarge` en `navy`; precio tachado en `muted`; `% OFF` en `coral`.

---

## Espaciado y formas

- **Grilla base:** múltiplos de **4** (`4, 8, 12, 16, 24, 32`).
- **Radios:** `sm 8` · `md 12` · `lg 16` · `pill 999`.
- **Sombras:** suaves, baja opacidad (elevación 1–2). Las tarjetas de producto
  usan borde `border` + sombra sutil.
- **Touch targets:** mínimo 44×44.

---

## Componentes base (a construir en Fase 3+)

| Componente | Notas |
|---|---|
| `AppButton` | Primario (violet), secundario (outline), texto. Estados loading/disabled. |
| `ProductCard` | Imagen 1:1, nombre (2 líneas), precio + precio tachado, badge oferta/destacado, botón favorito. |
| `CategoryChip` / `CategoryTile` | Ícono + nombre; grid en pantalla de categorías. |
| `AppTextField` | Label flotante, estados de error, prefijos/sufijos. |
| `PriceTag` | Formatea ARS (`$ 24.999`) con `intl` es_AR; muestra descuento. |
| `Badge` | "OFERTA" (saleGradient), "DESTACADO" (yellow), "NUEVO" (teal). |
| `EmptyState` / `ErrorState` | Ilustración + mensaje + acción. |
| `AppBottomNav` | Home · Categorías · Carrito · Favoritos · Perfil. |
| `QuantitySelector` | – / cantidad / + con límite de stock. |

---

## Iconografía

Material Symbols por defecto (los `iconName` de las categorías mapean a
íconos Material). Para la identidad de marca se reservan ilustraciones propias
en banners y estados vacíos (el "arte propio" del requerimiento).

---

## Modo oscuro

Se contempla `ThemeMode` (claro/oscuro/sistema) desde el diseño. La paleta
oscura se define en la Fase 3 reusando los mismos tokens de marca sobre
superficies oscuras (`ink` como fondo, `surface` elevado).

---

## Accesibilidad

- Contraste AA en texto sobre fondos de marca (validar `violet`/`coral` sobre
  blanco para textos chicos; usar `navy`/`ink` cuando haga falta).
- Soporte de `textScaleFactor` sin romper layouts.
- Labels semánticos en botones e íconos accionables.
