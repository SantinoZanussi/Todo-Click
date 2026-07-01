import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_grid.dart';
import '../widgets/product_list_args.dart';

/// Listado de productos para una [ProductListArgs] (categoría, "ver todo",
/// resultados). Permite ajustar filtros y orden mediante el bottom sheet.
class ProductListPage extends ConsumerStatefulWidget {
  const ProductListPage({required this.args, super.key});

  final ProductListArgs args;

  @override
  ConsumerState<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends ConsumerState<ProductListPage> {
  late ProductQuery _query = widget.args.query;

  Future<void> _openFilters() async {
    final updated = await showProductFilters(context, _query);
    if (updated != null) setState(() => _query = updated);
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsQueryProvider(_query));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.title),
        actions: [
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
      body: productsAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar los productos.',
          onRetry: () => ref.invalidate(productsQueryProvider(_query)),
        ),
        data: (products) => products.isEmpty
            ? EmptyStateView(
                icon: Icons.search_off,
                title: 'Sin resultados',
                message: 'Probá ajustar los filtros de búsqueda.',
                actionLabel: _query.hasActiveFilters ? 'Limpiar filtros' : null,
                onAction: _query.hasActiveFilters
                    ? () => setState(
                        () => _query = ProductQuery(
                          categoryId: _query.categoryId,
                          subcategoryId: _query.subcategoryId,
                          searchText: _query.searchText,
                        ),
                      )
                    : null,
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      0,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${products.length} producto(s)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  Expanded(child: ProductGrid(products: products)),
                ],
              ),
      ),
    );
  }
}
