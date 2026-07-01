import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';
import '../../domain/entities/product.dart';
import '../controllers/catalog_providers.dart';

/// Detalle de producto: galería, precio, stock, descripción, favorito y
/// (placeholder) agregar al carrito (se conecta en la Fase 6).
class ProductDetailPage extends ConsumerStatefulWidget {
  const ProductDetailPage({required this.productId, super.key});

  final String productId;

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  int _quantity = 1;
  int _imageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final productAsync = ref.watch(productByIdProvider(widget.productId));

    return Scaffold(
      body: productAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => Scaffold(
          appBar: AppBar(),
          body: ErrorStateView(
            message: 'No se pudo cargar el producto.',
            onRetry: () =>
                ref.invalidate(productByIdProvider(widget.productId)),
          ),
        ),
        data: (product) => _content(product),
      ),
      bottomNavigationBar: productAsync.maybeWhen(
        data: (product) => _bottomBar(product),
        orElse: () => null,
      ),
    );
  }

  Widget _content(Product product) {
    final isFavorite = ref
        .watch(favoritesControllerProvider)
        .contains(product.id);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 360,
          actions: [
            IconButton(
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite ? AppColors.coral : null,
              ),
              onPressed: () => ref
                  .read(favoritesControllerProvider.notifier)
                  .toggle(product.id),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(background: _gallery(product)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (product.isOnSale && product.discountPercentage > 0)
                      AppBadge.sale('-${product.discountPercentage.round()}%'),
                    if (product.isFeatured) ...[
                      const SizedBox(width: AppSpacing.sm),
                      AppBadge.featured(),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'SKU: ${product.sku}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: AppSpacing.lg),
                PriceTag(
                  price: product.price,
                  finalPrice: product.finalPrice,
                  discountPercentage: product.isOnSale
                      ? product.discountPercentage
                      : 0,
                  size: PriceTagSize.large,
                ),
                const SizedBox(height: AppSpacing.md),
                _stockChip(product),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Descripción',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  product.description.isEmpty
                      ? 'Sin descripción.'
                      : product.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _gallery(Product product) {
    if (product.images.isEmpty) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.image_outlined, size: 64, color: AppColors.muted),
        ),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        PageView.builder(
          itemCount: product.images.length,
          onPageChanged: (i) => setState(() => _imageIndex = i),
          itemBuilder: (_, i) => CachedNetworkImage(
            imageUrl: product.images[i],
            fit: BoxFit.cover,
            placeholder: (_, _) => Container(color: AppColors.background),
            errorWidget: (_, _, _) =>
                const Icon(Icons.broken_image_outlined, color: AppColors.muted),
          ),
        ),
        if (product.images.length > 1)
          Positioned(
            bottom: AppSpacing.md,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                product.images.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i == _imageIndex
                        ? AppColors.violet
                        : AppColors.white.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _stockChip(Product product) {
    final inStock = product.hasStock;
    return Row(
      children: [
        Icon(
          inStock ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: inStock ? AppColors.success : AppColors.coral,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          inStock ? 'En stock (${product.stock} disponibles)' : 'Sin stock',
          style: TextStyle(
            color: inStock ? AppColors.success : AppColors.coral,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _addToCart(Product product) {
    ref
        .read(cartControllerProvider.notifier)
        .addProduct(product, quantity: _quantity);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Producto agregado al carrito ✅'),
          action: SnackBarAction(
            label: 'Ver carrito',
            onPressed: () => context.go(AppRoutes.cart),
          ),
        ),
      );
  }

  Widget _bottomBar(Product product) {
    final canBuy = product.hasStock;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            if (canBuy) ...[
              QuantitySelector(
                quantity: _quantity,
                min: 1,
                max: product.stock,
                onChanged: (q) => setState(() => _quantity = q),
              ),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: AppButton(
                label: canBuy ? 'Agregar al carrito' : 'Sin stock',
                icon: canBuy ? Icons.add_shopping_cart : null,
                onPressed: canBuy ? () => _addToCart(product) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
