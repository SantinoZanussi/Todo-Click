import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../core/theme/app_spacing.dart';
import 'product_card.dart';

/// Skeleton **shimmer** para el estado de carga de las grillas de productos.
///
/// Reproduce la misma cuadrícula responsive y el mismo alto de celda que
/// [ProductGrid] (imagen + bloque de info), así el salto al contenido real es
/// imperceptible. Reemplaza al spinner en catálogo, búsqueda y favoritos.
class ProductGridSkeleton extends StatelessWidget {
  const ProductGridSkeleton({
    this.itemCount = 6,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  final int itemCount;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  int _columnsFor(double width) {
    if (width >= 1600) return 6;
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        const crossSpacing = AppSpacing.lg;
        final available = constraints.maxWidth - padding.horizontal;
        final cellWidth = (available - crossSpacing * (columns - 1)) / columns;
        return Shimmer.fromColors(
          baseColor: scheme.surfaceContainerHighest,
          highlightColor: Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.06),
            scheme.surfaceContainerHighest,
          ),
          child: GridView.builder(
            padding: padding,
            shrinkWrap: shrinkWrap,
            physics: physics,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: crossSpacing,
              mainAxisSpacing: AppSpacing.xxl,
              mainAxisExtent: ProductCard.heightForWidth(cellWidth),
            ),
            itemCount: itemCount,
            itemBuilder: (_, _) => const _SkeletonCard(),
          ),
        );
      },
    );
  }
}

/// Celda placeholder: caja de imagen + dos líneas de texto + línea de precio.
class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        bar(0.9, 12),
        const SizedBox(height: AppSpacing.sm),
        bar(0.6, 12),
        const SizedBox(height: AppSpacing.md),
        bar(0.4, 14),
      ],
    );
  }
}
