import 'package:flutter/material.dart';

/// Paleta de colores oficial de TodoClick, extraída del logo.
///
/// Estos son los *tokens crudos* de color. El `ThemeData` completo
/// (ColorScheme, tipografía, componentes) se construye sobre estos tokens
/// en la Fase 3 (`core/theme/app_theme.dart`). Mantener los colores acá,
/// en un único lugar, evita "magic colors" repartidos por la UI.
///
/// Referencia visual del logo:
///  - "Todo"  → azul marino  (texto principal)
///  - "Click" → multicolor: violeta, turquesa, coral, amarillo, azul royal
///  - Bolsa   → franjas violeta / turquesa / coral / amarillo / azul
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Marca (brand)
  // ---------------------------------------------------------------------------

  /// Azul marino del texto "Todo". Color de marca principal / texto fuerte.
  static const Color navy = Color(0xFF0B1B3A);

  /// Violeta — color PRIMARIO de la app (acentos, botones principales).
  static const Color violet = Color(0xFF6C2BD9);

  /// Turquesa — color SECUNDARIO.
  static const Color teal = Color(0xFF1FBFB8);

  /// Rojo coral — ofertas, descuentos, estados de error/alerta.
  static const Color coral = Color(0xFFF4435B);

  /// Amarillo — destacados, CTA secundarios, badges "destacado".
  static const Color yellow = Color(0xFFF9B233);

  /// Azul royal — links, acciones informativas.
  static const Color royalBlue = Color(0xFF2F6BFF);

  // ---------------------------------------------------------------------------
  // Semánticos (estado)
  // ---------------------------------------------------------------------------

  static const Color success = Color(0xFF1FA971);
  static const Color warning = Color(0xFFF9B233);
  static const Color error = coral;
  static const Color info = royalBlue;

  // ---------------------------------------------------------------------------
  // Neutros (grises) — base de superficies y textos
  // ---------------------------------------------------------------------------

  static const Color ink = Color(0xFF101524); // texto principal
  static const Color slate = Color(0xFF5B6478); // texto secundario
  static const Color muted = Color(0xFF9AA1B1); // texto deshabilitado / hints
  static const Color border = Color(0xFFE4E7EE); // bordes / divisores
  static const Color surface = Color(0xFFFFFFFF); // tarjetas
  static const Color background = Color(0xFFF6F7FB); // fondo de pantalla
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ---------------------------------------------------------------------------
  // Gradientes de marca (para banners, splash, CTA destacados)
  // ---------------------------------------------------------------------------

  /// Gradiente principal violeta → azul royal (identidad "Click").
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [violet, royalBlue],
  );

  /// Gradiente de ofertas coral → amarillo.
  static const LinearGradient saleGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [coral, yellow],
  );
}
