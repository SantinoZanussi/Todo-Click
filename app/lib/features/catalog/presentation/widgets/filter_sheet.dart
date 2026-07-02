import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';

/// Muestra el bottom sheet de filtros y devuelve la query actualizada
/// (o `null` si se cancela).
Future<ProductQuery?> showProductFilters(
  BuildContext context,
  ProductQuery current,
) {
  return showModalBottomSheet<ProductQuery>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FilterSheet(initial: current),
  );
}

class _FilterSheet extends ConsumerStatefulWidget {
  const _FilterSheet({required this.initial});

  final ProductQuery initial;

  @override
  ConsumerState<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<_FilterSheet> {
  late ProductQuery _query = widget.initial;
  late final TextEditingController _minCtrl = TextEditingController(
    text: widget.initial.minPrice?.toStringAsFixed(0) ?? '',
  );
  late final TextEditingController _maxCtrl = TextEditingController(
    text: widget.initial.maxPrice?.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));
    Navigator.pop(
      context,
      _query.copyWith(minPrice: min, maxPrice: max, clearPrices: false),
    );
  }

  void _clear() {
    Navigator.pop(
      context,
      ProductQuery(
        categoryId: widget.initial.categoryId,
        subcategoryId: widget.initial.subcategoryId,
        searchText: widget.initial.searchText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.lg),

            // Orden
            Text('Ordenar por', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              children: ProductSort.values.map((s) {
                return ChoiceChip(
                  label: Text(s.label),
                  selected: _query.sort == s,
                  onSelected: (_) =>
                      setState(() => _query = _query.copyWith(sort: s)),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Precio
            Text(
              'Rango de precio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(child: _priceField(_minCtrl, 'Mínimo')),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _priceField(_maxCtrl, 'Máximo')),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),

            // Disponibilidad / oferta
            Text(
              'Disponibilidad',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilterChip(
                  label: const Text('En stock'),
                  selected: _query.inStockOnly,
                  onSelected: (v) =>
                      setState(() => _query = _query.copyWith(inStockOnly: v)),
                ),
                FilterChip(
                  label: const Text('En oferta'),
                  selected: _query.onSaleOnly,
                  onSelected: (v) =>
                      setState(() => _query = _query.copyWith(onSaleOnly: v)),
                ),
              ],
            ),

            // Marca
            const SizedBox(height: AppSpacing.lg),
            brands.when(
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const SizedBox.shrink(),
              data: (list) => DropdownButtonFormField<String?>(
                initialValue: _query.brandId,
                decoration: const InputDecoration(labelText: 'Marca'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Todas')),
                  ...list.map(
                    (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                  ),
                ],
                onChanged: (v) => setState(
                  () => _query = v == null
                      ? _query.copyWith(clearBrand: true)
                      : _query.copyWith(brandId: v),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clear,
                    child: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceField(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, prefixText: r'$ '),
    );
  }
}
