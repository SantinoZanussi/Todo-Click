import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Selector de cantidad (– N +) con límites mínimo y máximo (stock).
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    required this.quantity,
    required this.onChanged,
    this.min = 1,
    this.max = 99,
    super.key,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final canDecrement = quantity > min;
    final canIncrement = quantity < max;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            Icons.remove,
            canDecrement ? () => onChanged(quantity - 1) : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          _btn(Icons.add, canIncrement ? () => onChanged(quantity + 1) : null),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap) {
    return IconButton(
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(
        icon,
        color: onTap == null ? AppColors.muted : AppColors.violet,
      ),
    );
  }
}
