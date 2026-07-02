import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/responsive/content_container.dart';
import '../../core/theme/app_spacing.dart';

/// Encabezado de página (H1) para las vistas anchas (tablet/desktop).
///
/// En mobile el título vive en la `AppBar`; en pantallas anchas la barra
/// superior es global (marca + navegación), así que cada página recupera su
/// título como un encabezado grande dentro del contenido, opcionalmente con una
/// acción a la derecha (p. ej. "Vaciar" en el carrito).
class PageHeading extends StatelessWidget {
  const PageHeading({
    required this.title,
    this.trailing,
    this.maxWidth,
    super.key,
  });

  final String title;
  final Widget? trailing;

  /// Ancho máximo del bloque, para alinear con el contenido de abajo.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ContentContainer(
      maxWidth: maxWidth ?? Breakpoints.maxContentWidth,
      child: Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.xxl,
          bottom: AppSpacing.lg,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}
