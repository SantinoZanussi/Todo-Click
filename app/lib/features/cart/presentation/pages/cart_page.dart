import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/cart_item.dart';
import '../controllers/cart_controller.dart';

/// Pantalla del carrito: ítems con control de cantidad, eliminar, subtotal y
/// botón para ir al checkout.
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, controller),
              child: const Text('Vaciar'),
            ),
        ],
      ),
      body: cart.isEmpty
          ? EmptyStateView(
              icon: Icons.shopping_cart_outlined,
              title: 'Tu carrito está vacío',
              message: 'Explorá el catálogo y sumá productos.',
              actionLabel: 'Ir al catálogo',
              onAction: () => context.go(AppRoutes.home),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => _CartItemTile(
                      item: cart.items[i],
                      onQuantity: (q) =>
                          controller.setQuantity(cart.items[i].productId, q),
                      onRemove: () =>
                          controller.removeProduct(cart.items[i].productId),
                    ),
                  ),
                ),
                _summaryBar(context, cart.subtotal),
              ],
            ),
    );
  }

  Widget _summaryBar(BuildContext context, double subtotal) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  Formatters.currency(subtotal),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: 'Continuar la compra',
              icon: Icons.arrow_forward,
              onPressed: () => context.push(AppRoutes.checkout),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClear(
    BuildContext context,
    CartController controller,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vaciar carrito'),
        content: const Text('¿Seguro que querés eliminar todos los productos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
    if (ok ?? false) controller.clear();
  }
}

class _CartItemTile extends StatelessWidget {
  const _CartItemTile({
    required this.item,
    required this.onQuantity,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQuantity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: SizedBox(
                width: 72,
                height: 72,
                child: item.imageUrl == null
                    ? Container(
                        color: AppColors.background,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.muted,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) =>
                            Container(color: AppColors.background),
                        errorWidget: (_, _, _) =>
                            const Icon(Icons.broken_image_outlined),
                      ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    Formatters.currency(item.unitPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      QuantitySelector(
                        quantity: item.quantity,
                        max: item.maxStock <= 0 ? 99 : item.maxStock,
                        onChanged: onQuantity,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: AppColors.coral,
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
