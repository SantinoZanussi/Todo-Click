import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'brand_colors.dart';

/// Construcción del `ThemeData` de TodoClick (Material 3) a partir de los
/// tokens de marca (`AppColors`). Expone temas claro y oscuro.
///
/// Rediseño estilo Gymshark:
///  - Tipografía **Archivo** (grotesca moderna) vía `google_fonts`.
///  - Alto contraste: superficies claras + acentos slate (`charcoal`).
///  - Esquinas crujientes (radios chicos) y componentes planos (sin sombras).
///  - Botones oscuros full-width con texto en mayúsculas y tracking amplio.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  /// Tracking (letter-spacing) para textos en mayúsculas de marca.
  static const double _uppercaseTracking = 1.2;

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    // Color de acción PRIMARIO adaptativo: slate sobre fondos claros, crema
    // sobre fondos oscuros. Así los botones (Elevated/Filled), chips y demás
    // superficies de acción siempre resaltan y su texto nunca desaparece —
    // el patrón "botón claro sobre slate" de Gymshark, en ambos modos.
    final primary = isLight ? AppColors.charcoal : AppColors.cream;
    final onPrimary = isLight ? AppColors.cream : AppColors.charcoal;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: AppColors.moss,
      onSecondary: AppColors.white,
      tertiary: AppColors.sage,
      onTertiary: AppColors.charcoal,
      error: AppColors.error,
      onError: AppColors.white,
      surface: isLight ? AppColors.surface : AppColors.darkSurface,
      onSurface: isLight ? AppColors.ink : AppColors.darkOnSurface,
      onSurfaceVariant: isLight ? AppColors.slate : AppColors.darkMuted,
      surfaceContainerLowest: isLight
          ? AppColors.background
          : AppColors.darkBackground,
      surfaceContainerHighest: isLight
          ? AppColors.cream
          : AppColors.darkSurfaceHigh,
      outline: isLight ? AppColors.border : AppColors.darkBorder,
    );

    // Tipografía de marca: Archivo aplicada sobre la base del sistema.
    final baseText = GoogleFonts.archivoTextTheme(
      isLight ? Typography.blackMountainView : Typography.whiteMountainView,
    );

    final textTheme = baseText
        .copyWith(
          displayLarge: baseText.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          displayMedium: baseText.displayMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
          headlineMedium: baseText.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
          headlineSmall: baseText.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          titleLarge: baseText.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          titleMedium: baseText.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          labelLarge: baseText.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: _uppercaseTracking,
          ),
        )
        .apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      extensions: [BrandColors.forBrightness(brightness)],

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          letterSpacing: 1.5,
          fontWeight: FontWeight.w700,
        ),
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          disabledBackgroundColor: colorScheme.onSurface.withValues(alpha: 0.12),
          disabledForegroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size.fromHeight(54),
          side: BorderSide(color: colorScheme.onSurface, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          textStyle: textTheme.labelLarge?.copyWith(letterSpacing: 0.8),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.charcoal, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: const TextStyle(color: AppColors.slate),
        hintStyle: const TextStyle(color: AppColors.muted),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primary,
        secondarySelectedColor: colorScheme.primary,
        checkmarkColor: colorScheme.onPrimary,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontSize: 12,
          letterSpacing: 0.8,
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          fontSize: 12,
          letterSpacing: 0.8,
          color: colorScheme.onPrimary,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: AppColors.cream,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.charcoal
                : AppColors.slate,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.charcoal
                : AppColors.slate,
          ),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: colorScheme.outline,
        thickness: 1,
        space: 1,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.charcoal,
        contentTextStyle: GoogleFonts.archivo(
          color: AppColors.cream,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
