import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';
import '../widgets/category_card.dart';
import '../widgets/product_list_args.dart';

/// Pantalla de Categorías: grilla de categorías; al tocar una se abre una hoja
/// con sus subcategorías (estilo Shein).
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  void _goToProducts(BuildContext context, String title, ProductQuery query) {
    context.push(
      AppRoutes.productList,
      extra: ProductListArgs(title: title, query: query),
    );
  }

  void _openCategory(BuildContext context, Category category) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.apps),
              title: Text('Ver todo en ${category.name}'),
              onTap: () {
                Navigator.pop(context);
                _goToProducts(
                  context,
                  category.name,
                  ProductQuery(categoryId: category.id),
                );
              },
            ),
            const Divider(),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: category.subcategories
                  .where((s) => s.isActive)
                  .map(
                    (s) => ActionChip(
                      label: Text(s.name),
                      onPressed: () {
                        Navigator.pop(context);
                        _goToProducts(
                          context,
                          s.name,
                          ProductQuery(
                            categoryId: category.id,
                            subcategoryId: s.id,
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.search),
          ),
        ],
      ),
      body: categories.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar las categorías.',
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (list) => list.isEmpty
            ? const EmptyStateView(
                icon: Icons.grid_view,
                title: 'Sin categorías',
                message: 'Todavía no hay categorías cargadas.',
              )
            : GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 180,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  childAspectRatio: 0.95,
                ),
                itemCount: list.length,
                itemBuilder: (_, i) => CategoryCard(
                  category: list[i],
                  onTap: () => _openCategory(context, list[i]),
                ),
              ),
      ),
    );
  }
}
