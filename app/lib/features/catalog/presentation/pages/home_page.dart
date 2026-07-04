import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/responsive/content_container.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../notifications/presentation/controllers/notifications_providers.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';
import '../widgets/category_tile.dart';
import '../widgets/product_card_tile.dart';
import '../widgets/product_carousel.dart';
import '../widgets/product_list_args.dart';

/// Home = **landing editorial** (Gymshark-style), responsive de verdad.
///
/// Ritmo de bloques con fondos alternados (slate → crema → página → musgo →
/// crema → slate), hero de campaña, mosaico de categorías con personalidad y
/// secciones de producto que se ven llenas incluso con catálogo escaso (una
/// card editorial "Ver todo" lidera la fila y las columnas se adaptan a la
/// cantidad). No toca lógica: consume los mismos providers y rutas.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  /// Ancho de contenido más generoso que el default: la Home respira a lo ancho
  /// como una tienda de escritorio real.
  static const double _homeMaxWidth = 1440;

  void _openCategory(BuildContext context, String id, String title) {
    context.push(
      AppRoutes.productList,
      extra: ProductListArgs(title: title, query: ProductQuery(categoryId: id)),
    );
  }

  void _openAll(BuildContext context, String title, ProductQuery query) {
    context.push(
      AppRoutes.productList,
      extra: ProductListArgs(title: title, query: query),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featured = ref.watch(featuredProductsProvider);
    final onSale = ref.watch(onSaleProductsProvider);
    final categories = ref.watch(categoriesProvider);
    final unread = ref.watch(unreadNotificationsProvider);
    final wide = context.isWide;

    final sectionGap = wide ? AppSpacing.xxxl : AppSpacing.xxl;

    return Scaffold(
      // En tablet/desktop la marca/búsqueda/notificaciones viven en la barra
      // superior global del shell; acá se omite la AppBar.
      appBar: wide
          ? null
          : AppBar(
              titleSpacing: AppSpacing.lg,
              title: Text(
                AppConstants.appName.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppColors.charcoal,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => context.push(AppRoutes.search),
                ),
                IconButton(
                  icon: Badge(
                    isLabelVisible: unread > 0,
                    label: Text('$unread'),
                    child: const Icon(Icons.notifications_none),
                  ),
                  onPressed: () => context.push(AppRoutes.notifications),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
            ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(featuredProductsProvider);
          ref.invalidate(onSaleProductsProvider);
          ref.invalidate(categoriesProvider);
        },
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 1 · Hero de campaña (full-bleed slate)
            _Hero(
              imageUrl: featured.valueOrNull?.isNotEmpty ?? false
                  ? featured.value!.first.mainImage
                  : null,
              onExplore: () =>
                  _openAll(context, 'Catálogo', const ProductQuery()),
              onOffers: () => _openAll(
                context,
                'Ofertas',
                const ProductQuery(onSaleOnly: true),
              ),
            ),

            // 2 · Barra de confianza (full-bleed crema)
            const _TrustBar(),

            SizedBox(height: sectionGap),

            // 3 · Categorías (mosaico editorial)
            _CategorySection(
              categories: categories,
              wide: wide,
              maxWidth: _homeMaxWidth,
              onOpen: (c) => _openCategory(context, c.id, c.name),
            ),
            SizedBox(height: sectionGap),

            // 4 · Destacados
            _Showcase(
              title: 'Destacados',
              kicker: 'Selección',
              subtitle: 'Lo nuevo de esta temporada',
              async: featured,
              wide: wide,
              maxWidth: _homeMaxWidth,
              accent: AppColors.charcoal,
              onAccent: AppColors.cream,
              onSeeAll: () =>
                  _openAll(context, 'Destacados', const ProductQuery()),
            ),
            SizedBox(height: sectionGap),

            // 5 · Banda promocional (full-bleed musgo)
            _PromoBand(
              maxWidth: _homeMaxWidth,
              onTap: () => _openAll(
                context,
                'Ofertas',
                const ProductQuery(onSaleOnly: true),
              ),
            ),
            SizedBox(height: sectionGap),

            // 6 · Ofertas
            _Showcase(
              title: 'Ofertas',
              kicker: 'Sale',
              subtitle: 'Descuentos por tiempo limitado',
              async: onSale,
              wide: wide,
              maxWidth: _homeMaxWidth,
              accent: AppColors.moss,
              onAccent: AppColors.cream,
              onSeeAll: () => _openAll(
                context,
                'Ofertas',
                const ProductQuery(onSaleOnly: true),
              ),
            ),
            SizedBox(height: sectionGap),

            // 7 · Descubrí más (tabs por categoría)
            _TabbedDiscovery(
              wide: wide,
              maxWidth: _homeMaxWidth,
              onOpenCategory: (id, name) => _openCategory(context, id, name),
            ),
            SizedBox(height: sectionGap),

            // 8 · Newsletter (full-bleed crema) + footer
            const _Newsletter(),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// 1 · HERO
// ===========================================================================

/// Hero de campaña full-bleed. Editorial a dos columnas en anchos grandes
/// (copy + visual), bloque apilado en mobile. Transmite marca aunque no haya
/// fotografía: el visual es un panel de campaña, no un vacío.
class _Hero extends StatelessWidget {
  const _Hero({
    required this.onExplore,
    required this.onOffers,
    this.imageUrl,
  });

  final VoidCallback onExplore;
  final VoidCallback onOffers;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (!context.isWide) {
      return _MobileHero(onExplore: onExplore, onOffers: onOffers);
    }

    final height = context.responsive(mobile: 520.0, tablet: 520.0, desktop: 640.0);
    return ColoredBox(
      color: AppColors.charcoal,
      child: SizedBox(
        height: height,
        child: ContentContainer(
          maxWidth: HomePage._homeMaxWidth,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 6,
                child: _HeroCopy(onExplore: onExplore, onOffers: onOffers),
              ),
              const SizedBox(width: AppSpacing.xxxl),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                  child: _HeroVisual(imageUrl: imageUrl),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.onExplore, required this.onOffers});

  final VoidCallback onExplore;
  final VoidCallback onOffers;

  @override
  Widget build(BuildContext context) {
    final headline = context.responsive(mobile: 48.0, tablet: 52.0, desktop: 72.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Kicker('Nueva temporada'),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'TODO,\nA UN CLICK',
          style: TextStyle(
            color: AppColors.cream,
            fontSize: headline,
            height: 0.95,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const SizedBox(
          width: 460,
          child: Text(
            'Miles de productos con envío a todo el país. Descubrí lo nuevo de esta temporada.',
            style: TextStyle(
              color: Color(0xCCEBF4DD),
              fontSize: 17,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            _LightButton(label: 'Explorar catálogo', onTap: onExplore),
            const SizedBox(width: AppSpacing.md),
            _OutlineLightButton(label: 'Ver ofertas', onTap: onOffers),
          ],
        ),
      ],
    );
  }
}

/// Panel visual del hero. Si hay imagen la usa a sangre; si no, arma un panel
/// de campaña (gradiente de marca + glifo fantasma + etiqueta) para que el
/// espacio se vea intencional en vez de vacío.
class _HeroVisual extends StatelessWidget {
  const _HeroVisual({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          fit: BoxFit.cover,
          placeholder: (_, _) => const _CampaignPanel(),
          errorWidget: (_, _, _) => const _CampaignPanel(),
        ),
      );
    }
    return const _CampaignPanel();
  }
}

class _CampaignPanel extends StatelessWidget {
  const _CampaignPanel();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.moss, AppColors.sage],
          ),
        ),
        child: Stack(
          children: [
            // Glifo fantasma de marca.
            Positioned(
              right: -30,
              bottom: -30,
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 260,
                color: AppColors.cream.withValues(alpha: 0.16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'COLECCIÓN\n2026',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 40,
                      height: 1.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomLeft,
                    child: _TagPill(label: 'ENVÍO A TODO EL PAÍS'),
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

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.charcoal,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.cream,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero({required this.onExplore, required this.onOffers});

  final VoidCallback onExplore;
  final VoidCallback onOffers;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: ColoredBox(
        color: AppColors.charcoal,
        child: Stack(
          children: [
            // Glifo fantasma de marca: rompe la planicie del bloque slate.
            Positioned(
              right: -34,
              top: -20,
              child: Icon(
                Icons.shopping_bag_outlined,
                size: 190,
                color: AppColors.cream.withValues(alpha: 0.05),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.xxxl,
                AppSpacing.xl,
                AppSpacing.xxxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _Kicker('Nueva temporada'),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'TODO,\nA UN CLICK',
                    style: TextStyle(
                      color: AppColors.cream,
                      fontSize: 44,
                      height: 0.98,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text(
                    'Miles de productos con envío a todo el país.',
                    style: TextStyle(
                      color: Color(0xCCEBF4DD),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _LightButton(
                    label: 'Explorar catálogo',
                    onTap: onExplore,
                    expand: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _OutlineLightButton(
                    label: 'Ver ofertas',
                    onTap: onOffers,
                    expand: true,
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

class _Kicker extends StatelessWidget {
  const _Kicker(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.sage,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
      ),
    );
  }
}

// ===========================================================================
// 2 · BARRA DE CONFIANZA
// ===========================================================================

class _TrustBar extends StatelessWidget {
  const _TrustBar();

  static const _items = [
    (Icons.local_shipping_outlined, 'Envío a todo el país', 'Correo Argentino'),
    (Icons.lock_outline, 'Pago seguro', 'Con Mercado Pago'),
    (Icons.autorenew, 'Cambios fáciles', 'Hasta 30 días'),
    (Icons.bolt_outlined, 'Ofertas semanales', 'Nuevas cada semana'),
  ];

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    return ColoredBox(
      color: AppColors.cream,
      child: ContentContainer(
        maxWidth: HomePage._homeMaxWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
          child: wide
              ? Row(
                  children: [
                    for (var i = 0; i < _items.length; i++) ...[
                      if (i > 0)
                        Container(
                          width: 1,
                          height: 40,
                          color: AppColors.charcoal.withValues(alpha: 0.12),
                        ),
                      Expanded(child: _TrustItem(item: _items[i])),
                    ],
                  ],
                )
              : Wrap(
                  runSpacing: AppSpacing.lg,
                  children: [
                    for (final item in _items)
                      SizedBox(
                        width: MediaQuery.sizeOf(context).width / 2 - AppSpacing.xl,
                        child: _TrustItem(item: item, compact: true),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.item, this.compact = false});

  final (IconData, String, String) item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: compact
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        Icon(item.$1, color: AppColors.charcoal, size: 26),
        const SizedBox(width: AppSpacing.md),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.$2,
              style: const TextStyle(
                color: AppColors.charcoal,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              item.$3,
              style: TextStyle(
                color: AppColors.charcoal.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ===========================================================================
// 3 · CATEGORÍAS (mosaico editorial)
// ===========================================================================

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.categories,
    required this.wide,
    required this.maxWidth,
    required this.onOpen,
  });

  final AsyncValue<List<Category>> categories;
  final bool wide;
  final double maxWidth;
  final void Function(Category category) onOpen;

  @override
  Widget build(BuildContext context) {
    return categories.when(
      loading: () => SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        final featuredCats = list.where((c) => c.isFeatured).toList();
        final shown = featuredCats.isEmpty ? list : featuredCats;
        if (shown.isEmpty) return const SizedBox.shrink();

        return ContentContainer(
          maxWidth: maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Comprá por categoría',
                kicker: 'Explorá',
                subtitle: 'Encontrá lo que buscás por rubro',
              ),
              const SizedBox(height: AppSpacing.lg),
              if (wide)
                _CategoryMosaic(categories: shown, onOpen: onOpen)
              else
                _CategoryRail(categories: shown, onOpen: onOpen),
            ],
          ),
        );
      },
    );
  }
}

/// Mosaico de escritorio: un banner destacado + una grilla de tiles altas.
class _CategoryMosaic extends StatelessWidget {
  const _CategoryMosaic({required this.categories, required this.onOpen});

  final List<Category> categories;
  final void Function(Category category) onOpen;

  @override
  Widget build(BuildContext context) {
    final feature = categories.first;
    final rest = categories.skip(1).take(8).toList();
    final columns = context.responsive(mobile: 2, tablet: 3, desktop: 4);

    return Column(
      children: [
        CategoryFeature(category: feature, onTap: () => onOpen(feature)),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.82,
            ),
            itemCount: rest.length,
            itemBuilder: (_, i) => CategoryTile(
              category: rest[i],
              tone: categoryToneAt(i + 1),
              labelBelow: true,
              onTap: () => onOpen(rest[i]),
            ),
          ),
        ],
      ],
    );
  }
}

/// Riel horizontal de categorías para mobile (tiles editoriales, no pills).
class _CategoryRail extends StatelessWidget {
  const _CategoryRail({required this.categories, required this.onOpen});

  final List<Category> categories;
  final void Function(Category category) onOpen;

  @override
  Widget build(BuildContext context) {
    final cats = categories.take(10).toList();
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => SizedBox(
          width: 140,
          child: CategoryTile(
            category: cats[i],
            tone: categoryToneAt(i),
            onTap: () => onOpen(cats[i]),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 4 / 6 · SECCIONES DE PRODUCTO (anti-vacío)
// ===========================================================================

/// Fila de productos que se ve llena aunque haya pocos ítems: en escritorio la
/// primera celda es una card editorial "Ver todo" y las columnas se ajustan a
/// la cantidad de productos. En mobile, carrusel horizontal.
class _Showcase extends StatelessWidget {
  const _Showcase({
    required this.title,
    required this.kicker,
    required this.subtitle,
    required this.async,
    required this.wide,
    required this.maxWidth,
    required this.accent,
    required this.onAccent,
    required this.onSeeAll,
  });

  final String title;
  final String kicker;
  final String subtitle;
  final AsyncValue<List<Product>> async;
  final bool wide;
  final double maxWidth;
  final Color accent;
  final Color onAccent;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => _shell(
        context,
        SizedBox(
          height: wide ? 360 : 272,
          child: const LoadingView(),
        ),
      ),
      error: (_, _) => _shell(
        context,
        const SizedBox(
          height: 120,
          child: ErrorStateView(
            message: 'No se pudieron cargar los productos.',
          ),
        ),
      ),
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        if (!wide) {
          return _shell(context, ProductCarousel(products: products));
        }
        return _shell(context, _wideGrid(context, products));
      },
    );
  }

  Widget _wideGrid(BuildContext context, List<Product> products) {
    final maxCols = context.responsive(mobile: 2, tablet: 3, desktop: 4);
    final shownProducts = products.take(maxCols * 2 - 1).toList();
    // Columnas = mínimo entre el tope y (productos + card editorial). Así una
    // fila SIEMPRE queda completa: 1 producto → 2 columnas grandes, etc.
    final columns = math.min(maxCols, shownProducts.length + 1);
    const crossSpacing = AppSpacing.lg;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth =
            (constraints.maxWidth - crossSpacing * (columns - 1)) / columns;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: AppSpacing.xxl,
            mainAxisExtent: ProductCard.heightForWidth(cellWidth),
          ),
          itemCount: shownProducts.length + 1,
          itemBuilder: (_, i) {
            if (i == 0) {
              return _CollectionCard(
                title: title,
                subtitle: subtitle,
                accent: accent,
                onAccent: onAccent,
                onTap: onSeeAll,
              );
            }
            return ProductCardTile(product: shownProducts[i - 1]);
          },
        );
      },
    );
  }

  Widget _shell(BuildContext context, Widget child) {
    final header = SectionHeader(
      title: title,
      kicker: kicker,
      actionLabel: 'Ver todo',
      onAction: onSeeAll,
    );
    if (wide) {
      return ContentContainer(
        maxWidth: maxWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [header, const SizedBox(height: AppSpacing.lg), child],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: header,
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}

/// Card editorial que lidera una fila de productos (rellena y da ritmo).
class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onAccent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Color onAccent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverScale(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: accent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subtitle.toUpperCase(),
                    style: TextStyle(
                      color: onAccent.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          color: onAccent,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ArrowLabel(label: 'Ver todo', color: onAccent),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 7 · DESCUBRÍ MÁS (tabs por categoría)
// ===========================================================================

/// Sección interactiva con pills de categoría: al tocar una, cambia la fila de
/// productos debajo (estilo "ESPERA, HAY MÁS…" de Gymshark). Reusa
/// `productsQueryProvider` por categoría; no toca lógica.
class _TabbedDiscovery extends ConsumerStatefulWidget {
  const _TabbedDiscovery({
    required this.wide,
    required this.maxWidth,
    required this.onOpenCategory,
  });

  final bool wide;
  final double maxWidth;
  final void Function(String id, String name) onOpenCategory;

  @override
  ConsumerState<_TabbedDiscovery> createState() => _TabbedDiscoveryState();
}

class _TabbedDiscoveryState extends ConsumerState<_TabbedDiscovery> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return categoriesAsync.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (list) {
        final featured = list.where((c) => c.isFeatured).toList();
        final cats = (featured.isEmpty ? list : featured).take(6).toList();
        if (cats.length < 2) return const SizedBox.shrink();
        final selectedId =
            cats.any((c) => c.id == _selectedId) ? _selectedId! : cats.first.id;
        final selected = cats.firstWhere((c) => c.id == selectedId);
        final productsAsync = ref.watch(
          productsQueryProvider(ProductQuery(categoryId: selectedId)),
        );

        final header = SectionHeader(
          title: 'Descubrí más',
          kicker: 'Para vos',
          actionLabel: 'Ver todo',
          onAction: () => widget.onOpenCategory(selected.id, selected.name),
        );
        final pills = _CategoryPills(
          categories: cats,
          selectedId: selectedId,
          onSelect: (id) => setState(() => _selectedId = id),
        );
        final content = productsAsync.when(
          loading: () => SizedBox(
            height: widget.wide ? 340 : 272,
            child: const LoadingView(),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) {
            if (items.isEmpty) return _EmptyDiscovery(name: selected.name);
            return widget.wide
                ? _grid(items)
                : ProductCarousel(products: items);
          },
        );

        if (widget.wide) {
          return ContentContainer(
            maxWidth: widget.maxWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: AppSpacing.md),
                pills,
                const SizedBox(height: AppSpacing.lg),
                content,
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: header,
            ),
            const SizedBox(height: AppSpacing.md),
            pills,
            const SizedBox(height: AppSpacing.md),
            content,
          ],
        );
      },
    );
  }

  Widget _grid(List<Product> items) {
    final maxCols = context.responsive(mobile: 2, tablet: 3, desktop: 4);
    final shown = items.take(maxCols).toList();
    return LayoutBuilder(
      builder: (context, constraints) {
        const crossSpacing = AppSpacing.lg;
        final cols = math.min(maxCols, shown.length);
        if (cols == 0) return const SizedBox.shrink();
        final cellWidth =
            (constraints.maxWidth - crossSpacing * (cols - 1)) / cols;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: crossSpacing,
            mainAxisSpacing: AppSpacing.xxl,
            mainAxisExtent: ProductCard.heightForWidth(cellWidth),
          ),
          itemCount: shown.length,
          itemBuilder: (_, i) => ProductCardTile(product: shown[i]),
        );
      },
    );
  }
}

/// Fila de pills de categoría (seleccionable). Selección = pill de acento.
class _CategoryPills extends StatelessWidget {
  const _CategoryPills({
    required this.categories,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Category> categories;
  final String selectedId;
  final void Function(String id) onSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: context.isWide ? 0 : AppSpacing.lg,
        ),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final c = categories[i];
          final sel = c.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(c.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: sel ? scheme.primary : scheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: sel ? scheme.primary : scheme.outline,
                ),
              ),
              child: Text(
                c.name.toUpperCase(),
                style: TextStyle(
                  color: sel ? scheme.onPrimary : scheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyDiscovery extends StatelessWidget {
  const _EmptyDiscovery({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        'Todavía no hay productos en $name.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ===========================================================================
// 5 · BANDA PROMOCIONAL
// ===========================================================================

class _PromoBand extends StatelessWidget {
  const _PromoBand({required this.onTap, required this.maxWidth});

  final VoidCallback onTap;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final title = Text(
      'HASTA 50% OFF',
      style: TextStyle(
        color: AppColors.cream,
        fontSize: wide ? 44 : 30,
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        height: 1.0,
      ),
    );
    const subtitle = Text(
      'Ofertas de temporada con envío a todo el país.',
      style: TextStyle(color: Color(0xE6EBF4DD), fontSize: 16, height: 1.4),
    );
    final cta = _LightButton(label: 'Ver ofertas', onTap: onTap);

    return ColoredBox(
      color: AppColors.moss,
      child: ContentContainer(
        maxWidth: maxWidth,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: wide ? AppSpacing.xxxl : AppSpacing.xxl,
          ),
          child: wide
              ? Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _Kicker('Sale'),
                          const SizedBox(height: AppSpacing.md),
                          title,
                          const SizedBox(height: AppSpacing.sm),
                          subtitle,
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xl),
                    cta,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Kicker('Sale'),
                    const SizedBox(height: AppSpacing.md),
                    title,
                    const SizedBox(height: AppSpacing.sm),
                    subtitle,
                    const SizedBox(height: AppSpacing.lg),
                    cta,
                  ],
                ),
        ),
      ),
    );
  }
}

// ===========================================================================
// 7 · NEWSLETTER
// ===========================================================================

/// Bloque de newsletter full-bleed (crema). Envío UI-only por ahora (pendiente
/// wiring backend); confirma con un SnackBar.
class _Newsletter extends StatefulWidget {
  const _Newsletter();

  @override
  State<_Newsletter> createState() => _NewsletterState();
}

class _NewsletterState extends State<_Newsletter> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _subscribe() {
    final email = _controller.text.trim();
    if (email.isEmpty) return;
    _controller.clear();
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Gracias por suscribirte!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = context.isWide;
    final field = TextField(
      controller: _controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _subscribe(),
      decoration: const InputDecoration(hintText: 'tu@email.com'),
    );
    final button = AppButton(label: 'Suscribirme', onPressed: _subscribe);

    return ColoredBox(
      color: AppColors.cream,
      child: ContentContainer(
        maxWidth: 760,
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: wide ? AppSpacing.xxxl : AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'SUMATE A TODOCLICK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.charcoal,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enterate primero de lanzamientos y ofertas exclusivas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.charcoal.withValues(alpha: 0.7),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (wide)
                Row(
                  children: [
                    Expanded(child: field),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(width: 180, child: button),
                  ],
                )
              else ...[
                field,
                const SizedBox(height: AppSpacing.md),
                button,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Compartidos
// ===========================================================================

/// Etiqueta con flecha (estilo "Ver todo →"), reutilizada en tiles y cards.
class _ArrowLabel extends StatelessWidget {
  const _ArrowLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 6),
        Icon(Icons.arrow_forward, size: 16, color: color),
      ],
    );
  }
}

/// Botón claro (crema) sobre fondos oscuros.
class _LightButton extends StatelessWidget {
  const _LightButton({
    required this.label,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: AppColors.cream,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.charcoal,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.arrow_forward, size: 18, color: AppColors.charcoal),
            ],
          ),
        ),
      ),
    );
    return content;
  }
}

/// Botón contorneado claro (crema) sobre fondos oscuros.
class _OutlineLightButton extends StatelessWidget {
  const _OutlineLightButton({
    required this.label,
    required this.onTap,
    this.expand = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: AppColors.cream.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.cream,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
