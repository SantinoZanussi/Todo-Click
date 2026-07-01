import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Etiqueta pequeña para destacar estados de un producto (oferta, destacado,
/// nuevo, sin stock). Soporta fondo sólido o gradiente.
class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.color,
    this.gradient,
    this.icon,
    super.key,
  });

  /// Badge de oferta (gradiente coral→amarillo).
  factory AppBadge.sale(String label) =>
      AppBadge(label: label, gradient: AppColors.saleGradient);

  /// Badge "Destacado".
  factory AppBadge.featured() =>
      const AppBadge(label: 'DESTACADO', color: AppColors.yellow);

  /// Badge "Nuevo".
  factory AppBadge.isNew() =>
      const AppBadge(label: 'NUEVO', color: AppColors.teal);

  /// Badge "Sin stock".
  factory AppBadge.outOfStock() =>
      const AppBadge(label: 'SIN STOCK', color: AppColors.slate);

  final String label;
  final Color? color;
  final Gradient? gradient;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? AppColors.violet) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: AppColors.white),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
