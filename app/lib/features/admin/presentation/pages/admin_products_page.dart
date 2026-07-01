import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../catalog/domain/entities/product.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';
import 'admin_product_form_page.dart';

/// Listado de productos del admin (incluye inactivos), con alta/edición/baja.
class AdminProductsPage extends ConsumerWidget {
  const AdminProductsPage({super.key});

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, [
    Product? p,
  ]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AdminProductFormPage(product: p)),
    );
    if (context.mounted) ref.invalidate(adminProductsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(adminProductsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo'),
      ),
      body: productsAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar los productos.',
          onRetry: () => ref.invalidate(adminProductsProvider),
        ),
        data: (products) => products.isEmpty
            ? const EmptyStateView(
                icon: Icons.inventory_2_outlined,
                title: 'Sin productos',
                message: 'Tocá "Nuevo" para cargar el primero.',
              )
            : ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final p = products[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.background,
                      backgroundImage: p.mainImage != null
                          ? NetworkImage(p.mainImage!)
                          : null,
                      child: p.mainImage == null
                          ? const Icon(
                              Icons.image_outlined,
                              color: AppColors.muted,
                            )
                          : null,
                    ),
                    title: Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${Formatters.currency(p.finalPrice)} · Stock: ${p.stock}'
                      '${p.isActive ? '' : ' · INACTIVO'}',
                      style: TextStyle(
                        color: p.isActive ? AppColors.slate : AppColors.coral,
                      ),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'edit') {
                          await _openForm(context, ref, p);
                        } else if (v == 'delete') {
                          final ok = await runAdminAction(
                            context,
                            () =>
                                ref.read(adminApiProvider).deleteProduct(p.id),
                            success: 'Producto desactivado',
                          );
                          if (ok) ref.invalidate(adminProductsProvider);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text('Desactivar'),
                        ),
                      ],
                    ),
                    onTap: () => _openForm(context, ref, p),
                  );
                },
              ),
      ),
    );
  }
}
