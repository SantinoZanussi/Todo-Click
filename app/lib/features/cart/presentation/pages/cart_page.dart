import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/content_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/brand_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/cart.dart';
import '../../domain/entities/cart_item.dart';
import '../controllers/cart_controller.dart';

/// Pantalla del carrito. Responsive:
///  - **mobile**: lista de ítems + barra de subtotal fija abajo.
///  - **desktop/tablet**: dos columnas — ítems a la izquierda y tarjeta de
///    resumen (sticky) a la derecha.
class CartPage extends ConsumerWidget {
  const CartPage({super.key});

  static const double _maxWidth = 1100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final controller = ref.read(cartControllerProvider.notifier);
    final wide = context.isWide;

    if (cart.isEmpty) {
      final empty = EmptyStateView(
        icon: Icons.shopping_cart_outlined,
        title: 'Tu carrito está vacío',
        message: 'Explorá el catálogo y sumá productos.',
        actionLabel: 'Ir al catálogo',
        onAction: () => context.go(AppRoutes.home),
      );
      return Scaffold(
        appBar: wide ? null : AppBar(title: const Text('Carrito')),
        body: wide
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PageHeading(title: 'Carrito', maxWidth: _maxWidth),
                  Expanded(child: empty),
                ],
              )
            : empty,
      );
    }

    final items = ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: wide ? 0 : AppSpacing.lg),
      itemCount: cart.items.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) => _CartItemTile(
        item: cart.items[i],
        onQuantity: (q) => controller.setQuantity(cart.items[i].productId, q),
        onRemove: () => controller.removeProduct(cart.items[i].productId),
      ),
    );

    if (wide) {
      return Scaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              title: 'Carrito',
              maxWidth: _maxWidth,
              trailing: TextButton(
                onPressed: () => _confirmClear(context, controller),
                child: const Text('Vaciar'),
              ),
            ),
            Expanded(
              child: ContentContainer(
                maxWidth: _maxWidth,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: items),
                    const SizedBox(width: AppSpacing.xxxl),
                    SizedBox(
                      width: 340,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        child: _CartSummaryCard(cart: cart),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito'),
        actions: [
          TextButton(
            onPressed: () => _confirmClear(context, controller),
            child: const Text('Vaciar'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: items),
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
          border: Border(
            top: BorderSide(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SUBTOTAL',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    letterSpacing: 1,
                    color: AppColors.slate,
                  ),
                ),
                Text(
                  Formatters.currency(subtotal),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
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

/// Tarjeta de resumen del carrito (columna derecha en escritorio).
class _CartSummaryCard extends StatelessWidget {
  const _CartSummaryCard({required this.cart});

  final Cart cart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final units = cart.items.fold<int>(0, (sum, i) => sum + i.quantity);
    return Container(
      decoration: BoxDecoration(
        color: BrandColors.of(context).sectionSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'RESUMEN',
            style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 1),
          ),
          const SizedBox(height: AppSpacing.lg),
          _row(
            context,
            'Subtotal ($units u.)',
            Formatters.currency(cart.subtotal),
          ),
          const SizedBox(height: AppSpacing.sm),
          _row(context, 'Envío', 'A calcular', muted: true),
          const Divider(height: AppSpacing.xl),
          _row(
            context,
            'Total',
            Formatters.currency(cart.subtotal),
            isTotal: true,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Continuar la compra',
            icon: Icons.arrow_forward,
            onPressed: () => context.push(AppRoutes.checkout),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'El envío y los impuestos se calculan en el checkout.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: AppColors.slate),
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool isTotal = false,
    bool muted = false,
  }) {
    final theme = Theme.of(context);
    final style = isTotal
        ? theme.textTheme.titleLarge
        : theme.textTheme.bodyLarge?.copyWith(
            color: muted ? theme.colorScheme.onSurfaceVariant : null,
          );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(value, style: style),
      ],
    );
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: SizedBox(
              width: 84,
              height: 84,
              child: item.imageUrl == null
                  ? const BrandPlaceholder(compact: true)
                  : CachedNetworkImage(
                      imageUrl: item.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, _) =>
                          const BrandPlaceholder(compact: true),
                      errorWidget: (_, _, _) =>
                          const BrandPlaceholder(compact: true),
                    ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1.25,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.slate,
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  Formatters.currency(item.unitPrice),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                QuantitySelector(
                  quantity: item.quantity,
                  max: item.maxStock <= 0 ? 99 : item.maxStock,
                  onChanged: onQuantity,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
