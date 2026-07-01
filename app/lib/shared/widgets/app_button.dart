import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Variantes visuales de [AppButton].
enum AppButtonVariant { primary, secondary, text }

/// Botón unificado de la app, con estado de carga e ícono opcional.
///
/// Encapsula los tres estilos de botón del design system para no repetir
/// configuraciones y garantizar consistencia. Cuando [isLoading] es `true`
/// muestra un spinner y deshabilita el tap.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation(AppColors.white),
            ),
          )
        : _content();

    final effectiveOnPressed = isLoading ? null : onPressed;

    final button = switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: effectiveOnPressed,
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        child: isLoading ? _loaderTinted(context) : _content(),
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        child: isLoading ? _loaderTinted(context) : _content(),
      ),
    };

    return fullWidth ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content() {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 8),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _loaderTinted(BuildContext context) => SizedBox(
    height: 22,
    width: 22,
    child: CircularProgressIndicator(
      strokeWidth: 2.4,
      valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.primary),
    ),
  );
}
