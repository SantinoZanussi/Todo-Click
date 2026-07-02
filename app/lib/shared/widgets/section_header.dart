import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Encabezado de sección con título y acción opcional ("Ver todo").
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            letterSpacing: 0.8,
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!.toUpperCase(),
              style: const TextStyle(
                color: AppColors.moss,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: 0.8,
                decoration: TextDecoration.underline,
                decorationColor: AppColors.moss,
              ),
            ),
          ),
      ],
    );
  }
}
