import 'package:flutter/material.dart';

/// Paleta de colores oficial de TodoClick.
///
/// Rediseño de marca inspirado en Gymshark: base clara, mucho aire, tipografía
/// oscura de alto contraste y una paleta natural (verdes salvia + slate).
/// Estos son los *tokens crudos* de color; el `ThemeData` completo se construye
/// sobre ellos en `core/theme/app_theme.dart`.
///
/// Paleta de marca:
///  - `cream`    #EBF4DD → fondos y secciones destacadas (tinte salvia claro)
///  - `sage`     #90AB8B → acento salvia, estados suaves, ilustraciones
///  - `moss`     #5A7863 → color secundario, links, éxito
///  - `charcoal` #3B4953 → color PRIMARIO: texto, botones, hero
///
/// Para no romper la app existente, los nombres semánticos previos
/// (`violet`, `navy`, `teal`, ...) se mantienen como **alias** que ahora
/// apuntan a la nueva paleta. La UI se re-mapea sola; las pantallas se van
/// refinando fase por fase.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Marca (brand) — nueva paleta natural
  // ---------------------------------------------------------------------------

  /// Salvia claro / crema. Fondos de sección, chips, superficies destacadas.
  static const Color cream = Color(0xFFEBF4DD);

  /// Verde salvia. Acento suave, ilustraciones, placeholders de imagen.
  static const Color sage = Color(0xFF90AB8B);

  /// Verde musgo. Color SECUNDARIO: links, botones alternos, éxito.
  static const Color moss = Color(0xFF5A7863);

  /// Slate oscuro. Color PRIMARIO: texto fuerte, botones, hero, navegación.
  static const Color charcoal = Color(0xFF3B4953);

  // ---------------------------------------------------------------------------
  // Alias semánticos previos → re-mapeados a la nueva paleta.
  // (Se conservan para que el código existente siga compilando sin cambios.)
  // ---------------------------------------------------------------------------

  /// (alias) Antes azul marino; ahora slate. Texto fuerte / precios.
  static const Color navy = charcoal;

  /// (alias) Antes violeta; ahora slate. Es el color PRIMARIO de la app.
  static const Color violet = charcoal;

  /// (alias) Antes turquesa; ahora musgo. Color secundario.
  static const Color teal = moss;

  /// (alias) Antes azul royal; ahora slate. Links / acciones de texto.
  static const Color royalBlue = charcoal;

  /// Terracota sobria — ofertas y errores (reemplaza el coral neón).
  static const Color coral = Color(0xFFB8503F);

  /// Ocre cálido — avisos / warning (reemplaza el amarillo saturado).
  static const Color yellow = Color(0xFFC79A3E);

  // ---------------------------------------------------------------------------
  // Semánticos (estado)
  // ---------------------------------------------------------------------------

  static const Color success = moss;
  static const Color warning = Color(0xFFC79A3E);
  static const Color error = coral;
  static const Color info = moss;

  // ---------------------------------------------------------------------------
  // Neutros — base de superficies y textos (tintados en verde muy sutil)
  // ---------------------------------------------------------------------------

  static const Color ink = Color(0xFF2C363D); // texto principal (slate profundo)
  static const Color slate = Color(0xFF6B7770); // texto secundario (gris verdoso)
  static const Color muted = Color(0xFF9BA79E); // texto deshabilitado / hints
  static const Color border = Color(0xFFE1E7D8); // bordes / divisores (salvia)
  static const Color surface = Color(0xFFFFFFFF); // tarjetas
  static const Color background = Color(0xFFFAFBF6); // fondo de pantalla (blanco cálido)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Neutros OSCUROS (modo dark) — tintados en el mismo verde sutil.
  //
  // El `ThemeData` oscuro y `BrandColors` se construyen a partir de estos tokens
  // (antes eran hex mágicos sueltos en `app_theme.dart`). Regla del rediseño:
  // NINGUNA superficie hardcodea un color claro con texto adaptativo encima
  // — eso es lo que hacía desaparecer el texto en modo oscuro.
  // ---------------------------------------------------------------------------

  static const Color darkBackground = Color(0xFF121715); // fondo de pantalla
  static const Color darkSurface = Color(0xFF1B211F); // tarjetas / superficies
  static const Color darkSurfaceHigh = Color(0xFF232A27); // secciones / chips
  static const Color darkOnSurface = Color(0xFFECF1E6); // texto principal
  static const Color darkBorder = Color(0xFF3A423E); // bordes / divisores
  static const Color darkMuted = Color(0xFF8A968C); // texto secundario / hints

  // ---------------------------------------------------------------------------
  // Gradientes — el rediseño es plano; se conservan los nombres para
  // compatibilidad, pero ahora son transiciones mínimas y sobrias.
  // ---------------------------------------------------------------------------

  /// Gradiente de marca (slate profundo) para hero / overlays.
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [charcoal, Color(0xFF2C363D)],
  );

  /// Gradiente de ofertas (musgo → salvia).
  static const LinearGradient saleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [moss, sage],
  );
}
