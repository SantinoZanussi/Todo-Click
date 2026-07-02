import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/widgets.dart';
import '../../../catalog/domain/entities/brand.dart';
import '../../../catalog/presentation/controllers/catalog_providers.dart';
import '../controllers/admin_providers.dart';
import '../widgets/admin_widgets.dart';

String _slugify(String s) => s
    .toLowerCase()
    .trim()
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

/// Gestión de marcas.
class AdminBrandsPage extends ConsumerWidget {
  const AdminBrandsPage({super.key});

  Future<void> _form(BuildContext context, WidgetRef ref, [Brand? b]) async {
    final nameCtrl = TextEditingController(text: b?.name ?? '');
    var isActive = b?.isActive ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocal) => AlertDialog(
          title: Text(b == null ? 'Nueva marca' : 'Editar marca'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nombre'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Activa'),
                value: isActive,
                onChanged: (v) => setLocal(() => isActive = v),
              ),
            ],
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
    final slug = b?.slug ?? _slugify(nameCtrl.text);
    final data = {
      'name': nameCtrl.text.trim(),
      'slug': slug,
      'isActive': isActive,
    };
    final api = ref.read(adminApiProvider);
    final ok = await runAdminAction(
      context,
      () => b == null ? api.createBrand(data) : api.updateBrand(b.id, data),
      success: 'Marca guardada',
    );
    if (ok) ref.invalidate(brandsProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Marcas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva'),
      ),
      body: brandsAsync.when(
        loading: () => const LoadingView(),
        error: (_, _) => ErrorStateView(
          message: 'No se pudieron cargar las marcas.',
          onRetry: () => ref.invalidate(brandsProvider),
        ),
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final b = list[i];
            return ListTile(
              leading: Icon(
                Icons.sell,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(b.name),
              subtitle: Text(b.slug),
              onTap: () => _form(context, ref, b),
            );
          },
        ),
      ),
    );
  }
}
