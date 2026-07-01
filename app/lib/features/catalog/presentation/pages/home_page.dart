import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../notifications/presentation/controllers/notifications_providers.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';
import '../widgets/category_icons.dart';
import '../widgets/product_carousel.dart';
import '../widgets/product_list_args.dart';

/// Home del catálogo: banner, categorías destacadas, destacados y ofertas
/// con datos reales de Firestore.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  void _openCategory(BuildContext context, String id, String title) {
    context.push(
      AppRoutes.productList,
      extra: ProductListArgs(
        title: title,
        query: ProductQuery(categoryId: id),
      ),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          AppConstants.appName,
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
          IconButton(
            icon: Badge(
              isLabelVisible: ref.watch(unreadNotificationsProvider) > 0,
              label: Text('${ref.watch(unreadNotificationsProvider)}'),
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
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _banner(context),
            ),

            // Categorías destacadas
            categories.when(
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: LinearProgressIndicator()),
              ),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) {
                final featuredCats = list.where((c) => c.isFeatured).toList();
                final shown = featuredCats.isEmpty ? list : featuredCats;
                return _categoryChips(context, shown);
              },
            ),
            const SizedBox(height: AppSpacing.xl),

            // Destacados
            _Section(
              title: 'Destacados',
              onSeeAll: () =>
                  _openAll(context, 'Destacados', const ProductQuery()),
              child: _carousel(featured),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Ofertas
            _Section(
              title: 'Ofertas 🔥',
              onSeeAll: () => _openAll(
                context,
                'Ofertas',
                const ProductQuery(onSaleOnly: true),
              ),
              child: _carousel(onSale),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _carousel(AsyncValue<List<Product>> async) {
    return async.when(
      loading: () => const SizedBox(height: 272, child: LoadingView()),
      error: (_, _) => const SizedBox(
        height: 120,
        child: ErrorStateView(message: 'No se pudieron cargar los productos.'),
      ),
      data: (products) => products.isEmpty
          ? const SizedBox(
              height: 100,
              child: Center(child: Text('Sin productos por ahora.')),
            )
          : ProductCarousel(products: products),
    );
  }

  Widget _categoryChips(BuildContext context, List categories) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (_, i) {
          final c = categories[i];
          return ActionChip(
            avatar: Icon(categoryIcon(c.iconName as String?), size: 18),
            label: Text(c.name as String),
            onPressed: () =>
                _openCategory(context, c.id as String, c.name as String),
          );
        },
      ),
    );
  }

  Widget _banner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Todo lo que buscás,\na un click',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            label: 'Explorar catálogo',
            icon: Icons.arrow_forward,
            fullWidth: false,
            variant: AppButtonVariant.secondary,
            onPressed: () =>
                _openAll(context, 'Catálogo', const ProductQuery()),
          ),
        ],
      ),
    );
  }
}

/// Sección con encabezado ("Ver todo") + contenido.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.onSeeAll});

  final String title;
  final Widget child;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SectionHeader(
            title: title,
            actionLabel: onSeeAll != null ? 'Ver todo' : null,
            onAction: onSeeAll,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}
