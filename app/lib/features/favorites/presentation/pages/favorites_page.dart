import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../catalog/presentation/widgets/product_grid.dart';
import '../controllers/favorites_controller.dart';

/// Pantalla de Favoritos: grilla de los productos marcados (local + sync).
class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: favoritesAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar tus favoritos.',
          onRetry: () => ref.invalidate(favoriteProductsProvider),
        ),
        data: (products) => products.isEmpty
            ? EmptyStateView(
                icon: Icons.favorite_border,
                title: 'Sin favoritos todavía',
                message: 'Tocá el corazón en un producto para guardarlo acá.',
                actionLabel: 'Explorar catálogo',
                onAction: () => context.go(AppRoutes.home),
              )
            : ProductGrid(products: products),
      ),
    );
  }
}
