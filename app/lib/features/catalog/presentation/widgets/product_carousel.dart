import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/product.dart';
import 'product_card_tile.dart';

/// Lista horizontal de productos (secciones del home en mobile). El alto se
/// deriva del ancho de la card para que coincida exacto con la grilla.
class ProductCarousel extends StatelessWidget {
  const ProductCarousel({required this.products, this.itemWidth = 168, super.key});

  final List<Product> products;
  final double itemWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: ProductCard.heightForWidth(itemWidth),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) =>
            SizedBox(width: itemWidth, child: ProductCardTile(product: products[i])),
      ),
    );
  }
}
