import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/responsive/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/catalog/domain/entities/product.dart';
import 'app_badge.dart';
import 'brand_placeholder.dart';
import 'price_tag.dart';

/// Tarjeta de producto **premium** (estilo Gymshark) para grillas y carruseles.
///
/// La imagen es la protagonista (sin chrome de Material: nada de bordes ni
/// sombras). En hover (escritorio) la imagen hace un zoom sutil y se revela una
/// barra "Agregar"; en mobile un botón "+" queda siempre visible. El favorito,
/// el tap al detalle y el quick-add se delegan por callbacks (usa la lógica
/// existente, no la modifica).
class ProductCard extends StatefulWidget {
  const ProductCard({
    required this.product,
    this.onTap,
    this.onFavoriteToggle,
    this.onQuickAdd,
    this.isFavorite = false,
    this.heroTag,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onQuickAdd;
  final bool isFavorite;

  /// Si se provee, la imagen se envuelve en un [Hero] con este tag para que
  /// "vuele" hacia el detalle. Debe ser único por pantalla (lo activan solo las
  /// grillas donde cada producto aparece una vez).
  final Object? heroTag;

  /// Proporción de la imagen (ancho/alto). Ligeramente vertical = más editorial.
  static const double imageAspectRatio = 0.82;

  /// Alto reservado para el bloque de texto (nombre 2 líneas + precio).
  static const double infoHeight = 92;

  /// Alto total de la card para un ancho dado. Lo usan la grilla y el carrusel
  /// para dimensionar cada celda exacto (sin vacíos ni overflow).
  static double heightForWidth(double width) =>
      width / imageAspectRatio + infoHeight;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hover = false;
  bool _pressed = false;

  Product get _product => widget.product;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wide = context.isWide;
    final canQuickAdd = widget.onQuickAdd != null && _product.hasStock;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _pressed ? 0.94 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: ColoredBox(
                  color: scheme.surfaceContainerHighest,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _hover ? 1.06 : 1.0,
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOut,
                        child: widget.heroTag == null
                            ? _image()
                            : Hero(tag: widget.heroTag!, child: _image()),
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        left: AppSpacing.sm,
                        child: _badges(),
                      ),
                      if (widget.onFavoriteToggle != null)
                        Positioned(
                          top: AppSpacing.xs,
                          right: AppSpacing.xs,
                          child: _favoriteButton(),
                        ),
                      if (canQuickAdd) _quickAdd(wide),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _info(scheme),
          ],
        ),
        ),
      ),
    );
  }

  Widget _info(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _product.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
            height: 1.25,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        PriceTag(
          price: _product.price,
          finalPrice: _product.finalPrice,
          discountPercentage: _product.isOnSale
              ? _product.discountPercentage
              : 0,
          size: PriceTagSize.small,
        ),
      ],
    );
  }

  Widget _image() {
    final url = _product.mainImage;
    if (url == null) return const BrandPlaceholder();
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (_, _) => const BrandPlaceholder(),
      errorWidget: (_, _, _) => const BrandPlaceholder(),
    );
  }

  /// Producto cargado en las últimas 3 semanas → merece la etiqueta "NUEVO".
  bool get _isNew {
    final days = DateTime.now().difference(_product.createdAt).inDays;
    return days >= 0 && days <= 21;
  }

  Widget _badges() {
    if (!_product.hasStock) return AppBadge.outOfStock();
    if (_product.isOnSale && _product.discountPercentage > 0) {
      return AppBadge.sale('-${_product.discountPercentage.round()}%');
    }
    if (_isNew) return AppBadge.isNew();
    if (_product.isFeatured) return AppBadge.featured();
    return const SizedBox.shrink();
  }

  Widget _favoriteButton() {
    return Material(
      color: AppColors.white.withValues(alpha: 0.92),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: IconButton(
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 450),
          switchInCurve: Curves.elasticOut,
          transitionBuilder: (child, anim) => ScaleTransition(
            scale: anim,
            child: child,
          ),
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(widget.isFavorite),
            color: widget.isFavorite ? AppColors.coral : AppColors.charcoal,
          ),
        ),
        onPressed: widget.onFavoriteToggle,
      ),
    );
  }

  /// Quick-add: barra "Agregar" revelada en hover (escritorio) o botón "+"
  /// siempre visible (mobile).
  Widget _quickAdd(bool wide) {
    if (!wide) {
      return Positioned(
        right: AppSpacing.sm,
        bottom: AppSpacing.sm,
        child: Material(
          color: AppColors.charcoal,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: IconButton(
            iconSize: 20,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add, color: AppColors.cream),
            onPressed: widget.onQuickAdd,
          ),
        ),
      );
    }
    return Positioned(
      left: AppSpacing.sm,
      right: AppSpacing.sm,
      bottom: AppSpacing.sm,
      child: IgnorePointer(
        ignoring: !_hover,
        child: AnimatedSlide(
          offset: _hover ? Offset.zero : const Offset(0, 0.5),
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _hover ? 1 : 0,
            duration: const Duration(milliseconds: 160),
            child: Material(
              color: AppColors.charcoal,
              borderRadius: BorderRadius.circular(AppRadius.md),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onQuickAdd,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'AGREGAR',
                        style: TextStyle(
                          color: AppColors.cream,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Icon(Icons.add, size: 16, color: AppColors.cream),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
