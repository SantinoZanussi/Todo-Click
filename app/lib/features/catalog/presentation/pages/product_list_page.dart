import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/responsive/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_filters_panel.dart';
import '../widgets/product_grid.dart';
import '../widgets/product_list_args.dart';

/// Listado de productos para una [ProductListArgs] (categoría, "ver todo",
/// resultados). Responsive:
///  - **desktop**: panel de filtros lateral + toolbar de orden + grilla ancha.
///  - **tablet**: toolbar (orden + botón de filtros) + grilla.
///  - **mobile**: grilla + filtros en bottom sheet (comportamiento original).
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({required this.args, super.key});

  final ProductListArgs args;

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  late ProductQuery _query = widget.args.query;

  void _setQuery(ProductQuery q) => setState(() => _query = q);

  Future<void> _openFilters() async {
    final updated = await showProductFilters(context, _query);
    if (updated != null) _setQuery(updated);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsQueryProvider(_query));
    final device = context.deviceType;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.title),
        actions: [
          if (device == DeviceType.mobile)
            IconButton(
              tooltip: 'Filtros',
              icon: Badge(
                isLabelVisible: _query.hasActiveFilters,
                child: const Icon(Icons.tune),
              ),
              onPressed: _openFilters,
            ),
        ],
      ),
      body: switch (device) {
        DeviceType.desktop => _buildWide(productsAsync, sidebar: true),
        DeviceType.tablet => _buildWide(productsAsync, sidebar: false),
        DeviceType.mobile => _buildMobile(productsAsync),
      },
    );
  }

  // ------------------------------ Mobile ------------------------------------

  Widget _buildMobile(AsyncValue<List<Product>> async) {
    return async.when(
      loading: () => const ProductGridSkeleton(),
      error: (_, _) => ErrorStateView(
        message: 'No se pudieron cargar los productos.',
        onRetry: () => ref.invalidate(productsQueryProvider(_query)),
      ),
      data: (products) => products.isEmpty
          ? _empty()
          : Column(
              children: [
                _CollectionHeader(
                  title: widget.args.title,
                  count: products.length,
                ),
                Expanded(child: ProductGrid(products: products)),
              ],
            ),
    );
  }

  // -------------------------- Desktop / tablet ------------------------------

  Widget _buildWide(AsyncValue<List<Product>> async, {required bool sidebar}) {
    final content = async.when(
      loading: () => const ProductGridSkeleton(
        padding: EdgeInsets.all(AppSpacing.xl),
      ),
      error: (_, _) => ErrorStateView(
        message: 'No se pudieron cargar los productos.',
        onRetry: () => ref.invalidate(productsQueryProvider(_query)),
      ),
      data: (products) => products.isEmpty
          ? _empty()
          : ProductGrid(
              products: products,
              padding: const EdgeInsets.all(AppSpacing.xl),
            ),
    );

    return Column(
      children: [
        _Toolbar(
          count: async.valueOrNull?.length,
          sort: _query.sort,
          onSort: (s) => _setQuery(_query.copyWith(sort: s)),
          filtersActive: _query.hasActiveFilters,
          onFilters: sidebar ? null : _openFilters,
        ),
        Expanded(
          child: sidebar
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 288,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: ProductFiltersPanel(
                          query: _query,
                          onChanged: _setQuery,
                        ),
                      ),
                    ),
                    Expanded(child: content),
                  ],
                )
              : content,
        ),
      ],
    );
  }

  // ------------------------------- Comunes ----------------------------------

  Widget _empty() => EmptyStateView(
    icon: Icons.search_off,
    title: 'Sin resultados',
    message: 'Probá ajustar los filtros de búsqueda.',
    actionLabel: _query.hasActiveFilters ? 'Limpiar filtros' : null,
    onAction: _query.hasActiveFilters
        ? () => _setQuery(
            ProductQuery(
              categoryId: _query.categoryId,
              subcategoryId: _query.subcategoryId,
              searchText: _query.searchText,
            ),
          )
        : null,
  );

}

/// Encabezado de colección (mobile): kicker + título grande + cantidad. Le da
/// a la lista el aire de "colección" de una tienda, en vez de una grilla suelta.
class _CollectionHeader extends StatelessWidget {
  const _CollectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'COLECCIÓN',
            style: TextStyle(
              color: AppColors.moss,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title.toUpperCase(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$count ${count == 1 ? 'producto' : 'productos'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Toolbar superior: contador de resultados + orden (y botón de filtros en
/// tablet, cuando no hay panel lateral).
class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.count,
    required this.sort,
    required this.onSort,
    required this.filtersActive,
    this.onFilters,
  });

  final int? count;
  final ProductSort sort;
  final ValueChanged<ProductSort> onSort;
  final bool filtersActive;
  final VoidCallback? onFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Row(
        children: [
          Text(
            count == null ? '' : '$count PRODUCTO(S)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.slate,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          if (onFilters != null) ...[
            // Ancho acotado: un OutlinedButton como hijo NO-flex de un Row con
            // un Spacer al lado se mide con ancho infinito y rompe el layout.
            SizedBox(
              width: 132,
              child: OutlinedButton.icon(
                onPressed: onFilters,
                icon: Badge(
                  isLabelVisible: filtersActive,
                  child: const Icon(Icons.tune, size: 18),
                ),
                label: const Text('Filtros'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
          ],
          const Text(
            'ORDENAR',
            style: TextStyle(
              color: AppColors.slate,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          DropdownButtonHideUnderline(
            child: DropdownButton<ProductSort>(
              value: sort,
              borderRadius: BorderRadius.circular(AppRadius.md),
              items: ProductSort.values
                  .map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  )
                  .toList(),
              onChanged: (s) {
                if (s != null) onSort(s);
              },
            ),
          ),
        ],
      ),
    );
  }
}
