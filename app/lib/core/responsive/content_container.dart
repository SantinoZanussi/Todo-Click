import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import 'breakpoints.dart';

/// Centra el contenido con un **ancho máximo** y márgenes (gutters) que crecen
/// con la pantalla.
///
/// Es la pieza clave contra el efecto "app móvil estirada": en un monitor
/// ancho el contenido queda centrado y legible (máx. [maxWidth]) con aire a los
/// costados, en lugar de ocupar 1920 px de borde a borde. En mobile es
/// prácticamente transparente (solo aplica el padding lateral estándar).
class ContentContainer extends StatelessWidget {
  const ContentContainer({
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.padded = true,
    super.key,
  });

  final Widget child;

  /// Ancho máximo del contenido antes de que aparezcan márgenes laterales.
  final double maxWidth;

  /// Si aplica el padding horizontal responsive. Desactivar para secciones que
  /// gestionan su propio padding interno (p. ej. un hero full-bleed).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final gutter = context.responsive(
      mobile: AppSpacing.lg,
      tablet: AppSpacing.xl,
      desktop: AppSpacing.xxxl,
    );
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padded
              ? EdgeInsets.symmetric(horizontal: gutter)
              : EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}
