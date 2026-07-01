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
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(actionLabel!),
                const Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: AppColors.royalBlue,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
