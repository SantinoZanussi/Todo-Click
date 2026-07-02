import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';
import '../../domain/entities/product.dart';

/// [ProductCard] conectado: resuelve el estado de favorito, el quick-add al
/// carrito y la navegación al detalle. Es el tile que se usa en grillas y
/// listas del catálogo. Sólo orquesta lógica existente (no la modifica).
class ProductCardTile extends ConsumerWidget {
  const ProductCardTile({required this.product, super.key});

  final Product product;

  void _quickAdd(BuildContext context, WidgetRef ref) {
    ref.read(cartControllerProvider.notifier).addProduct(product);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${product.name} agregado al carrito'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesControllerProvider);
    return ProductCard(
      product: product,
      isFavorite: favorites.contains(product.id),
      onFavoriteToggle: () =>
          ref.read(favoritesControllerProvider.notifier).toggle(product.id),
      onQuickAdd: () => _quickAdd(context, ref),
      onTap: () => context.push(AppRoutes.productDetailOf(product.id)),
    );
  }
}
