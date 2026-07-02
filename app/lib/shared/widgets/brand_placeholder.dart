import 'package:flutter/material.dart';

import '../../core/theme/brand_colors.dart';

/// Placeholder de imagen **de marca** para cuando un producto o categoría no
/// tiene foto.
///
/// En vez del clásico ícono gris de "imagen rota" (que grita "falta contenido"
/// y encima quedaba crema brillante en modo oscuro), pinta una superficie
/// tintada de marca con un mono-ícono sutil y, opcionalmente, la etiqueta.
/// Se ve intencional en ambos modos porque toma sus colores de [BrandColors].
class BrandPlaceholder extends StatelessWidget {
  const BrandPlaceholder({
    this.icon = Icons.shopping_bag_outlined,
    this.label,
    this.compact = false,
    super.key,
  });

  /// Ícono central (por defecto la bolsa de la marca).
  final IconData icon;

  /// Etiqueta opcional bajo el ícono (se oculta en modo [compact]).
  final String? label;

  /// Versión reducida: ícono chico y sin etiqueta (miniaturas, celdas chicas).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final brand = BrandColors.of(context);
    final ink = brand.placeholderInk;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            brand.placeholderFill,
            Color.alphaBlend(
              ink.withValues(alpha: 0.12),
              brand.placeholderFill,
            ),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 22 : 40,
              color: ink.withValues(alpha: 0.55),
            ),
            if (!compact && label != null) ...[
              const SizedBox(height: 10),
              Text(
                label!.toUpperCase(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink.withValues(alpha: 0.75),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
