import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/content_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../cart/presentation/controllers/cart_controller.dart';
import '../../../favorites/presentation/controllers/favorites_controller.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';
import '../widgets/product_carousel.dart';
import '../widgets/product_grid.dart';

/// Detalle de producto. Responsive:
///  - **mobile**: galería full-width arriba (SliverAppBar) + info + barra
///    inferior fija para comprar.
///  - **desktop/tablet**: galería a la izquierda (imagen grande + miniaturas) e
///    info + comprar a la derecha; recomendados debajo.
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
    final wide = context.isWide;

    return productAsync.when(
      loading: () => Scaffold(appBar: AppBar(), body: const LoadingView()),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorStateView(
          message: 'No se pudo cargar el producto.',
          onRetry: () => ref.invalidate(productByIdProvider(widget.productId)),
        ),
      ),
      data: (product) => wide ? _wideScaffold(product) : _mobileScaffold(product),
    );
  }

  // ------------------------------ Mobile ------------------------------------

  Widget _mobileScaffold(Product product) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 360,
            actions: [_favButton(product)],
            flexibleSpace: FlexibleSpaceBar(background: _gallery(product)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerInfo(product, wide: false),
                  const SizedBox(height: AppSpacing.xl),
                  const Divider(),
                  const SizedBox(height: AppSpacing.lg),
                  _descriptionBlock(product),
                  const SizedBox(height: AppSpacing.xl),
                  _perks(),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _recommendations(product, wide: false)),
        ],
      ),
      bottomNavigationBar: _bottomBar(product),
    );
  }

  // -------------------------- Desktop / tablet ------------------------------

  Widget _wideScaffold(Product product) {
    return Scaffold(
      appBar: AppBar(actions: [_favButton(product)]),
      body: SingleChildScrollView(
        child: ContentContainer(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 6,
                      child: _WideGallery(
                        product: product,
                        index: _imageIndex,
                        onSelect: (i) => setState(() => _imageIndex = i),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxxl),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _headerInfo(product, wide: true),
                          const SizedBox(height: AppSpacing.xl),
                          _buyControls(product),
                          const SizedBox(height: AppSpacing.xl),
                          _perks(),
                          const SizedBox(height: AppSpacing.xl),
                          const Divider(),
                          const SizedBox(height: AppSpacing.lg),
                          _descriptionBlock(product),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxxl),
                _recommendations(product, wide: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------- Bloques compartidos ----------------------------

  Widget _headerInfo(Product product, {required bool wide}) {
    final theme = Theme.of(context);
    return Column(
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
          style: wide ? theme.textTheme.headlineLarge : theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'SKU: ${product.sku}',
          style: theme.textTheme.bodySmall?.copyWith(color: AppColors.muted),
        ),
        const SizedBox(height: AppSpacing.lg),
        PriceTag(
          price: product.price,
          finalPrice: product.finalPrice,
          discountPercentage: product.isOnSale ? product.discountPercentage : 0,
          size: PriceTagSize.large,
        ),
        const SizedBox(height: AppSpacing.md),
        _stockChip(product),
      ],
    );
  }

  Widget _descriptionBlock(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIPCIÓN',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            letterSpacing: 1,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          product.description.isEmpty ? 'Sin descripción.' : product.description,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ],
    );
  }

  /// Beneficios de compra (envío / cambios / pago). Da confianza y aire, con
  /// datos reales de la operación.
  Widget _perks() {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: const [
          _PerkRow(
            icon: Icons.local_shipping_outlined,
            title: 'Envío a todo el país',
            subtitle: 'Con Correo Argentino · seguimiento en tiempo real',
          ),
          SizedBox(height: AppSpacing.md),
          _PerkRow(
            icon: Icons.autorenew,
            title: 'Cambios fáciles',
            subtitle: 'Hasta 30 días para cambios y devoluciones',
          ),
          SizedBox(height: AppSpacing.md),
          _PerkRow(
            icon: Icons.lock_outline,
            title: 'Pago seguro',
            subtitle: 'Con Mercado Pago · tarjetas y cuotas',
          ),
        ],
      ),
    );
  }

  /// Selector de cantidad + botón comprar en línea (para desktop/tablet).
  Widget _buyControls(Product product) {
    final canBuy = product.hasStock;
    if (!canBuy) {
      return const AppButton(label: 'Sin stock', onPressed: null);
    }
    return Row(
      children: [
        QuantitySelector(
          quantity: _quantity,
          min: 1,
          max: product.stock,
          onChanged: (q) => setState(() => _quantity = q),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AppButton(
            label: 'Agregar al carrito',
            icon: Icons.add_shopping_cart,
            onPressed: () => _addToCart(product),
          ),
        ),
      ],
    );
  }

  Widget _recommendations(Product product, {required bool wide}) {
    final related = ref.watch(
      productsQueryProvider(ProductQuery(categoryId: product.categoryId)),
    );
    return related.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (list) {
        final items = list.where((p) => p.id != product.id).toList();
        if (items.isEmpty) return const SizedBox.shrink();
        const header = SectionHeader(title: 'También te puede interesar');
        if (wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              header,
              const SizedBox(height: AppSpacing.lg),
              ProductGrid(
                products: items.take(5).toList(),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: header,
            ),
            const SizedBox(height: AppSpacing.md),
            ProductCarousel(products: items),
            const SizedBox(height: AppSpacing.xxl),
          ],
        );
      },
    );
  }

  IconButton _favButton(Product product) {
    final isFavorite = ref
        .watch(favoritesControllerProvider)
        .contains(product.id);
    return IconButton(
      icon: Icon(
        isFavorite ? Icons.favorite : Icons.favorite_border,
        color: isFavorite ? AppColors.coral : null,
      ),
      onPressed: () =>
          ref.read(favoritesControllerProvider.notifier).toggle(product.id),
    );
  }

  /// Galería full-width para mobile (SliverAppBar): PageView + indicador.
  Widget _gallery(Product product) {
    if (product.images.isEmpty) {
      return const BrandPlaceholder(icon: Icons.image_outlined);
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
            placeholder: (_, _) => const BrandPlaceholder(),
            errorWidget: (_, _, _) => const BrandPlaceholder(),
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
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: i == _imageIndex ? 22 : 8,
                  height: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    color: i == _imageIndex
                        ? AppColors.charcoal
                        : AppColors.white.withValues(alpha: 0.8),
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
          content: const Text('Producto agregado al carrito'),
          action: SnackBarAction(
            label: 'Ver carrito',
            onPressed: () => context.go(AppRoutes.cart),
          ),
        ),
      );
  }

  /// Barra inferior fija para comprar (solo mobile).
  Widget _bottomBar(Product product) {
    final canBuy = product.hasStock;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
      ),
      child: SafeArea(
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
      ),
    );
  }
}

/// Galería de escritorio: imagen principal grande + tira de miniaturas.
class _WideGallery extends StatelessWidget {
  const _WideGallery({
    required this.product,
    required this.index,
    required this.onSelect,
  });

  final Product product;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final images = product.images;
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: const BrandPlaceholder(icon: Icons.image_outlined),
        ),
      );
    }

    final safeIndex = index.clamp(0, images.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: ColoredBox(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: CachedNetworkImage(
                imageUrl: images[safeIndex],
                fit: BoxFit.cover,
                placeholder: (_, _) => const BrandPlaceholder(),
                errorWidget: (_, _, _) => const BrandPlaceholder(),
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, i) => _Thumb(
                url: images[i],
                selected: i == safeIndex,
                onTap: () => onSelect(i),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, required this.selected, required this.onTap});

  final String url;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 76,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.outline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (_, _) => const BrandPlaceholder(compact: true),
          errorWidget: (_, _, _) => const BrandPlaceholder(compact: true),
        ),
      ),
    );
  }
}

/// Fila de beneficio (ícono + título + subtítulo) del bloque de compra.
class _PerkRow extends StatelessWidget {
  const _PerkRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: theme.colorScheme.onSurface),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.slate,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
