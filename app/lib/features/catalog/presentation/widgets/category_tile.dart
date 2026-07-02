import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/category.dart';
import 'category_icons.dart';

/// Tono de marca para las tiles de categoría (fondo + texto legible encima).
/// Rotar estos tonos por índice da la sensación editorial (no una grilla plana)
/// y funciona igual en claro y oscuro (son colores de marca intencionales).
class CategoryTone {
  const CategoryTone(this.background, this.foreground);
  final Color background;
  final Color foreground;
}

const List<CategoryTone> kCategoryTones = [
  CategoryTone(AppColors.charcoal, AppColors.cream),
  CategoryTone(AppColors.moss, AppColors.cream),
  CategoryTone(AppColors.sage, AppColors.charcoal),
];

CategoryTone categoryToneAt(int index) =>
    kCategoryTones[index % kCategoryTones.length];

/// Tile de categoría **editorial** (vertical): imagen a sangre con velo — o, si
/// no hay foto, un fondo de marca sólido — con el nombre en mayúsculas
/// superpuesto y un ícono sutil. Reemplaza los viejos swatches con gradiente.
class CategoryTile extends StatelessWidget {
  const CategoryTile({
    required this.category,
    required this.tone,
    this.onTap,
    super.key,
  });

  final Category category;
  final CategoryTone tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        category.imageUrl != null && category.imageUrl!.isNotEmpty;
    return HoverScale(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: tone.background,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasImage)
                  CachedNetworkImage(
                    imageUrl: category.imageUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
                if (hasImage)
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xCC2C363D)],
                        stops: [0.4, 1],
                      ),
                    ),
                  ),
                Positioned(
                  top: AppSpacing.md,
                  left: AppSpacing.md,
                  child: Icon(
                    categoryIcon(category.iconName),
                    size: 26,
                    color: (hasImage ? AppColors.cream : tone.foreground)
                        .withValues(alpha: 0.55),
                  ),
                ),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Text(
                    category.name.toUpperCase(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: hasImage ? AppColors.cream : tone.foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      letterSpacing: 0.3,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner de categoría destacada (ancho completo, corto). Da el punto de
/// asimetría editorial a la grilla de categorías (un tamaño distinto arriba).
class CategoryFeature extends StatelessWidget {
  const CategoryFeature({
    required this.category,
    this.onTap,
    this.kicker = 'Destacada',
    this.actionLabel = 'Ver productos',
    this.height = 240,
    super.key,
  });

  final Category category;
  final VoidCallback? onTap;
  final String kicker;
  final String actionLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final hasImage =
        category.imageUrl != null && category.imageUrl!.isNotEmpty;
    return HoverScale(
      scale: 1.01,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Material(
          color: AppColors.charcoal,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: height,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasImage)
                    CachedNetworkImage(
                      imageUrl: category.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => const SizedBox.shrink(),
                    ),
                  Positioned(
                    right: -20,
                    bottom: -40,
                    child: Icon(
                      categoryIcon(category.iconName),
                      size: 220,
                      color: AppColors.cream.withValues(alpha: 0.10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          kicker.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.sage,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2.5,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.cream,
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  actionLabel.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.cream,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward,
                                  size: 16,
                                  color: AppColors.cream,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
