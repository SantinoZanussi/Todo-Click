import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Encabezado de sección editorial: kicker (eyebrow) opcional + título y, a la
/// derecha, una acción opcional ("Ver todo"). El kicker y el subtítulo agregan
/// densidad/jerarquía sin depender de imágenes.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.kicker,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? kicker;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kicker != null) ...[
                Text(
                  kicker!.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.moss,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              Text(
                title.toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(letterSpacing: 0.8),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: TextButton(
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
          ),
      ],
    );
  }
}
