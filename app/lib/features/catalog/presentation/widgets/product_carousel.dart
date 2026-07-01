import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/product.dart';
import 'product_card_tile.dart';

/// Lista horizontal de productos (para secciones del home).
class ProductCarousel extends StatelessWidget {
  const ProductCarousel({required this.products, this.height = 272, super.key});

  final List<Product> products;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) =>
            SizedBox(width: 160, child: ProductCardTile(product: products[i])),
      ),
    );
  }
}
