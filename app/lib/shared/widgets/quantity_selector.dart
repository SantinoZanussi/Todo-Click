import 'package:flutter/material.dart';

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
    final scheme = Theme.of(context).colorScheme;
    final canDecrement = quantity > min;
    final canIncrement = quantity < max;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.onSurface, width: 1.4),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _btn(
            Icons.remove,
            canDecrement ? () => onChanged(quantity - 1) : null,
            scheme,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '$quantity',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          _btn(
            Icons.add,
            canIncrement ? () => onChanged(quantity + 1) : null,
            scheme,
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, VoidCallback? onTap, ColorScheme scheme) {
    return IconButton(
      iconSize: 18,
      visualDensity: VisualDensity.compact,
      onPressed: onTap,
      icon: Icon(
        icon,
        color: onTap == null ? scheme.onSurfaceVariant : scheme.onSurface,
      ),
    );
  }
}
