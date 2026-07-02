import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tokens de marca **conscientes del brightness** que el `ColorScheme` de
/// Material no expresa por sí solo.
///
/// Su razón de existir es la regla de oro del rediseño: ninguna superficie
/// debe hardcodear un color con texto adaptativo encima (eso hacía que en modo
/// oscuro el texto desapareciera). Cada token resuelve su versión clara y
/// oscura, así los widgets piden "la superficie de sección de marca" o "el
/// relleno de un placeholder" y siempre obtienen algo legible.
///
/// Acceso: `final brand = BrandColors.of(context);`
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.sectionSurface,
    required this.onSectionSurface,
    required this.placeholderFill,
    required this.placeholderInk,
    required this.priceStrike,
    required this.discount,
    required this.onDiscount,
    required this.heroSurface,
    required this.onHero,
    required this.onHeroMuted,
    required this.kicker,
  });

  /// Superficie "crema" de marca para bandas y tarjetas destacadas.
  /// Claro: crema salvia. Oscuro: slate elevado (mantiene legibilidad).
  final Color sectionSurface;

  /// Texto/íconos sobre [sectionSurface].
  final Color onSectionSurface;

  /// Relleno del placeholder de imagen (cuando un producto no tiene foto).
  final Color placeholderFill;

  /// Tinte del ícono/marca dentro del placeholder.
  final Color placeholderInk;

  /// Precio de lista tachado (atenuado).
  final Color priceStrike;

  /// Color de descuento / ofertas. Terracota de marca, fijo en ambos modos.
  final Color discount;

  /// Texto sobre [discount].
  final Color onDiscount;

  /// Banda de marca oscura (hero, promo, footer). Fija en ambos modos: es un
  /// bloque slate intencional con texto claro encima.
  final Color heroSurface;

  /// Texto principal sobre [heroSurface] (crema).
  final Color onHero;

  /// Texto secundario sobre [heroSurface] (crema atenuada).
  final Color onHeroMuted;

  /// Kicker / eyebrow de marca (salvia).
  final Color kicker;

  static const BrandColors light = BrandColors(
    sectionSurface: AppColors.cream,
    onSectionSurface: AppColors.charcoal,
    placeholderFill: AppColors.cream,
    placeholderInk: AppColors.sage,
    priceStrike: AppColors.muted,
    discount: AppColors.coral,
    onDiscount: AppColors.white,
    heroSurface: AppColors.charcoal,
    onHero: AppColors.cream,
    onHeroMuted: Color(0xCCEBF4DD),
    kicker: AppColors.sage,
  );

  static const BrandColors dark = BrandColors(
    sectionSurface: AppColors.darkSurfaceHigh,
    onSectionSurface: AppColors.darkOnSurface,
    placeholderFill: AppColors.darkSurfaceHigh,
    placeholderInk: AppColors.sage,
    priceStrike: AppColors.darkMuted,
    discount: AppColors.coral,
    onDiscount: AppColors.white,
    heroSurface: AppColors.charcoal,
    onHero: AppColors.cream,
    onHeroMuted: Color(0xCCEBF4DD),
    kicker: AppColors.sage,
  );

  /// Resuelve la extensión del tema actual (cae a [light] si no está registrada).
  static BrandColors of(BuildContext context) =>
      Theme.of(context).extension<BrandColors>() ?? light;

  static BrandColors forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  @override
  BrandColors copyWith({
    Color? sectionSurface,
    Color? onSectionSurface,
    Color? placeholderFill,
    Color? placeholderInk,
    Color? priceStrike,
    Color? discount,
    Color? onDiscount,
    Color? heroSurface,
    Color? onHero,
    Color? onHeroMuted,
    Color? kicker,
  }) {
    return BrandColors(
      sectionSurface: sectionSurface ?? this.sectionSurface,
      onSectionSurface: onSectionSurface ?? this.onSectionSurface,
      placeholderFill: placeholderFill ?? this.placeholderFill,
      placeholderInk: placeholderInk ?? this.placeholderInk,
      priceStrike: priceStrike ?? this.priceStrike,
      discount: discount ?? this.discount,
      onDiscount: onDiscount ?? this.onDiscount,
      heroSurface: heroSurface ?? this.heroSurface,
      onHero: onHero ?? this.onHero,
      onHeroMuted: onHeroMuted ?? this.onHeroMuted,
      kicker: kicker ?? this.kicker,
    );
  }

  @override
  BrandColors lerp(BrandColors? other, double t) {
    if (other == null) return this;
    return BrandColors(
      sectionSurface: Color.lerp(sectionSurface, other.sectionSurface, t)!,
      onSectionSurface: Color.lerp(onSectionSurface, other.onSectionSurface, t)!,
      placeholderFill: Color.lerp(placeholderFill, other.placeholderFill, t)!,
      placeholderInk: Color.lerp(placeholderInk, other.placeholderInk, t)!,
      priceStrike: Color.lerp(priceStrike, other.priceStrike, t)!,
      discount: Color.lerp(discount, other.discount, t)!,
      onDiscount: Color.lerp(onDiscount, other.onDiscount, t)!,
      heroSurface: Color.lerp(heroSurface, other.heroSurface, t)!,
      onHero: Color.lerp(onHero, other.onHero, t)!,
      onHeroMuted: Color.lerp(onHeroMuted, other.onHeroMuted, t)!,
      kicker: Color.lerp(kicker, other.kicker, t)!,
    );
  }
}
