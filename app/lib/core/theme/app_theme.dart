import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

/// Construcción del `ThemeData` de TodoClick (Material 3) a partir de los
/// tokens de marca (`AppColors`). Expone temas claro y oscuro.
///
/// La tipografía usa la fuente del sistema por ahora; la familia de marca
/// (Inter) se agrega como asset en una iteración posterior sin cambiar esta
/// estructura (solo se setea `fontFamily`).
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.violet,
      onPrimary: AppColors.white,
      secondary: AppColors.teal,
      onSecondary: AppColors.white,
      tertiary: AppColors.royalBlue,
      onTertiary: AppColors.white,
      error: AppColors.error,
      onError: AppColors.white,
      surface: isLight ? AppColors.surface : const Color(0xFF161A28),
      onSurface: isLight ? AppColors.ink : const Color(0xFFE9ECF5),
      surfaceContainerLowest: isLight
          ? AppColors.background
          : const Color(0xFF0E111B),
      surfaceContainerHighest: isLight
          ? const Color(0xFFEEF1F7)
          : const Color(0xFF1F2433),
      outline: isLight ? AppColors.border : const Color(0xFF323848),
    );

    final baseText = isLight
        ? Typography.blackMountainView
        : Typography.whiteMountainView;

    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      textTheme: textTheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,

      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: colorScheme.outline),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.violet,
          foregroundColor: AppColors.white,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.violet,
          minimumSize: const Size.fromHeight(52),
          side: const BorderSide(color: AppColors.violet, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.royalBlue),
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
          borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        hintStyle: TextStyle(color: AppColors.muted),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: AppColors.violet,
        labelStyle: textTheme.labelLarge,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: AppColors.violet.withValues(alpha: 0.14),
        elevation: 3,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelSmall?.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.violet
                : AppColors.slate,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.violet
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
        backgroundColor: AppColors.navy,
        contentTextStyle: const TextStyle(color: AppColors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
    );
  }
}
