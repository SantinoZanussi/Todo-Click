import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/product.dart';
import 'product_card_tile.dart';

/// Grilla responsive de productos. La cantidad de columnas se adapta al ancho
/// disponible (2 en mobile, hasta 6 en pantallas anchas / web) y cada celda se
/// dimensiona exacto con [ProductCard.heightForWidth] (nada de vacíos u
/// overflow por un `childAspectRatio` fijo).
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    required this.products,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.shrinkWrap = false,
    this.physics,
    super.key,
  });

  final List<Product> products;
  final EdgeInsets padding;

  /// Para anidar la grilla dentro de otro scroll (p. ej. el ListView del home).
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _columnsFor(constraints.maxWidth);
        const crossSpacing = AppSpacing.lg;
        final available = constraints.maxWidth - padding.horizontal;
        final cellWidth =
            (available - crossSpacing * (columns - 1)) / columns;
        return GridView.builder(
          padding: padding,
          shrinkWrap: shrinkWrap,
          physics: physics,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: AppSpacing.xxl,
            mainAxisExtent: ProductCard.heightForWidth(cellWidth),
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => ProductCardTile(product: products[i]),
        );
      },
    );
  }
}
