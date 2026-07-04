import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';

/// Panel de filtros del catálogo para pantallas anchas (columna lateral).
///
/// Reusa el mismo [ProductQuery] que el bottom sheet de mobile
/// (`filter_sheet.dart`), pero filtra **en vivo**: cada cambio emite la query
/// actualizada por [onChanged], sin botón "Aplicar" (patrón moderno de tienda).
/// El precio se aplica al confirmar el campo. El orden se controla aparte, en la
/// toolbar superior.
class ProductFiltersPanel extends ConsumerStatefulWidget {
  const ProductFiltersPanel({
    required this.query,
    required this.onChanged,
    super.key,
  });

  final ProductQuery query;
  final ValueChanged<ProductQuery> onChanged;

  @override
  ConsumerState<ProductFiltersPanel> createState() =>
      _ProductFiltersPanelState();
}

class _ProductFiltersPanelState extends ConsumerState<ProductFiltersPanel> {
  late final TextEditingController _minCtrl = TextEditingController(
    text: widget.query.minPrice?.toStringAsFixed(0) ?? '',
  );
  late final TextEditingController _maxCtrl = TextEditingController(
    text: widget.query.maxPrice?.toStringAsFixed(0) ?? '',
  );

  @override
  void dispose() {
    _minCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  ProductQuery get _q => widget.query;

  bool get _hasSecondaryFilters =>
      _q.minPrice != null ||
      _q.maxPrice != null ||
      _q.inStockOnly ||
      _q.onSaleOnly ||
      _q.brandId != null;

  void _applyPrice() {
    final min = double.tryParse(_minCtrl.text.replaceAll(',', '.'));
    final max = double.tryParse(_maxCtrl.text.replaceAll(',', '.'));
    if (min == null && max == null) {
      widget.onChanged(_q.copyWith(clearPrices: true));
    } else {
      widget.onChanged(_q.copyWith(minPrice: min, maxPrice: max));
    }
  }

  void _clearAll() {
    _minCtrl.clear();
    _maxCtrl.clear();
    // Reset de filtros secundarios; se conservan categoría/búsqueda y el orden.
    widget.onChanged(
      ProductQuery(
        categoryId: _q.categoryId,
        subcategoryId: _q.subcategoryId,
        searchText: _q.searchText,
        sort: _q.sort,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = ref.watch(brandsProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FILTROS',
              style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 1),
            ),
            if (_hasSecondaryFilters)
              TextButton(
                onPressed: _clearAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                ),
                child: const Text('Limpiar'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        _accordion(
          'Rango de precio',
          child: Row(
            children: [
              Expanded(child: _priceField(_minCtrl, 'Mín')),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _priceField(_maxCtrl, 'Máx')),
            ],
          ),
        ),
        const Divider(height: 1),

        _accordion(
          'Disponibilidad',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilterChip(
                label: const Text('En stock'),
                selected: _q.inStockOnly,
                onSelected: (v) => widget.onChanged(_q.copyWith(inStockOnly: v)),
              ),
              FilterChip(
                label: const Text('En oferta'),
                selected: _q.onSaleOnly,
                onSelected: (v) => widget.onChanged(_q.copyWith(onSaleOnly: v)),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        _accordion(
          'Marca',
          child: brands.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, _) => const SizedBox.shrink(),
            data: (list) => DropdownButtonFormField<String?>(
              // key para que refleje resets externos (Limpiar) del brandId.
              key: ValueKey(_q.brandId ?? '_all'),
              initialValue: _q.brandId,
              isExpanded: true,
              items: [
                const DropdownMenuItem(value: null, child: Text('Todas')),
                ...list.map(
                  (b) => DropdownMenuItem(value: b.id, child: Text(b.name)),
                ),
              ],
              onChanged: (v) => widget.onChanged(
                v == null
                    ? _q.copyWith(clearBrand: true)
                    : _q.copyWith(brandId: v),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Grupo de filtro colapsable (acordeón), abierto por defecto y sin las
  /// líneas divisorias propias del `ExpansionTile`.
  Widget _accordion(String title, {required Widget child}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: AppColors.slate,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        initiallyExpanded: true,
        tilePadding: EdgeInsets.zero,
        shape: const Border(),
        collapsedShape: const Border(),
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.md),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [child],
      ),
    );
  }

  Widget _priceField(TextEditingController ctrl, String label) => TextField(
    controller: ctrl,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onEditingComplete: _applyPrice,
    onSubmitted: (_) => _applyPrice(),
    decoration: InputDecoration(labelText: label, prefixText: r'$ '),
  );
}
