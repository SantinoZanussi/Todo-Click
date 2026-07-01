import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/catalog/domain/entities/product.dart';
import 'app_badge.dart';
import 'price_tag.dart';

/// Tarjeta de producto para grillas del catálogo (home, categorías, búsqueda).
///
/// Muestra imagen, badges (oferta/destacado/sin stock), nombre y precio.
/// El botón de favorito y el tap se delegan vía callbacks.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    this.onTap,
    this.onFavoriteToggle,
    this.isFavorite = false,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final bool isFavorite;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen + badges + favorito
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _image(),
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: _badges(),
                  ),
                  if (onFavoriteToggle != null)
                    Positioned(
                      top: AppSpacing.xs,
                      right: AppSpacing.xs,
                      child: _favoriteButton(),
                    ),
                ],
              ),
            ),
            // Nombre + precio
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  PriceTag(
                    price: product.price,
                    finalPrice: product.finalPrice,
                    discountPercentage: product.isOnSale
                        ? product.discountPercentage
                        : 0,
                    size: PriceTagSize.small,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final url = product.mainImage;
    if (url == null) {
      return Container(
        color: AppColors.background,
        child: const Icon(
          Icons.image_outlined,
          color: AppColors.muted,
          size: 40,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => Container(color: AppColors.background),
      errorWidget: (_, _, _) => Container(
        color: AppColors.background,
        child: const Icon(Icons.broken_image_outlined, color: AppColors.muted),
      ),
    );
  }

  Widget _badges() {
    if (!product.hasStock) return AppBadge.outOfStock();
    if (product.isOnSale && product.discountPercentage > 0) {
      return AppBadge.sale('-${product.discountPercentage.round()}%');
    }
    if (product.isFeatured) return AppBadge.featured();
    return const SizedBox.shrink();
  }

  Widget _favoriteButton() {
    return Material(
      color: AppColors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      child: IconButton(
        iconSize: 20,
        visualDensity: VisualDensity.compact,
        icon: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          color: isFavorite ? AppColors.coral : AppColors.slate,
        ),
        onPressed: onFavoriteToggle,
      ),
    );
  }
}
