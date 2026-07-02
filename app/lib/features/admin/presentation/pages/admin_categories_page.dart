import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../catalog/domain/entities/category.dart';
import '../../../catalog/presentation/controllers/catalog_providers.dart';
import '../../../catalog/presentation/widgets/category_icons.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

String _slugify(String s) => s
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// Gestión de categorías (alta/edición de los campos de nivel superior).
class AdminCategoriesPage extends ConsumerWidget {
  const AdminCategoriesPage({super.key});

  Future<void> _form(BuildContext context, WidgetRef ref, [Category? c]) async {
    final nameCtrl = TextEditingController(text: c?.name ?? '');
    final iconCtrl = TextEditingController(text: c?.iconName ?? '');
    final orderCtrl = TextEditingController(text: '${c?.order ?? 0}');
    var isActive = c?.isActive ?? true;
    var isFeatured = c?.isFeatured ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(c == null ? 'Nueva categoría' : 'Editar categoría'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  controller: iconCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Ícono (ej: devices, home)',
                  ),
                ),
                TextField(
                  controller: orderCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Orden'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activa'),
                  value: isActive,
                  onChanged: (v) => setLocal(() => isActive = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Destacada'),
                  value: isFeatured,
                  onChanged: (v) => setLocal(() => isFeatured = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !context.mounted) return;
    final slug = c?.slug ?? _slugify(nameCtrl.text);
    final data = {
      'name': nameCtrl.text.trim(),
      'slug': slug,
      'iconName': iconCtrl.text.trim().isEmpty ? null : iconCtrl.text.trim(),
      'order': int.tryParse(orderCtrl.text) ?? 0,
      'isActive': isActive,
      'isFeatured': isFeatured,
    };
    final api = ref.read(adminApiProvider);
    final ok = await runAdminAction(
      context,
      () =>
          c == null ? api.createCategory(data) : api.updateCategory(c.id, data),
      success: 'Categoría guardada',
    );
    if (ok) ref.invalidate(categoriesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Categorías')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: categoriesAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar las categorías.',
          onRetry: () => ref.invalidate(categoriesProvider),
        ),
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final c = list[i];
            return ListTile(
              leading: Icon(
                categoryIcon(c.iconName),
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(c.name),
              subtitle: Text('${c.subcategories.length} subcategorías'),
              trailing: c.isFeatured
                  ? const Icon(Icons.star, color: AppColors.yellow, size: 18)
                  : null,
              onTap: () => _form(context, ref, c),
            );
          },
        ),
      ),
    );
  }
}
