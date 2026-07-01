import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/product.dart';
import 'product_card_tile.dart';

/// Grilla responsive de productos. La cantidad de columnas se adapta al ancho
/// disponible (2 en mobile, hasta 4-5 en pantallas anchas / web).
class ProductGrid extends StatelessWidget {
  const ProductGrid({
    required this.products,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    super.key,
  });

  final List<Product> products;
  final EdgeInsets padding;

  int _columnsFor(double width) {
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
        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.62,
          ),
          itemCount: products.length,
          itemBuilder: (_, i) => ProductCardTile(product: products[i]),
        );
      },
    );
  }
}
