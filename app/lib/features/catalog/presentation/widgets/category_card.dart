import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/category.dart';
import 'category_icons.dart';

/// Tarjeta de categoría (ícono + nombre) para la grilla de categorías.
class CategoryCard extends StatelessWidget {
  const CategoryCard({required this.category, this.onTap, super.key});

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.violet.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  categoryIcon(category.iconName),
                  color: AppColors.violet,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
