import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/entities/product_query.dart';
import '../controllers/catalog_providers.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/product_grid.dart';

/// Búsqueda de productos por texto, con debounce y filtros.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  ProductQuery? _query; // null = aún no se buscó nada

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.debounceSearch, () {
      final text = value.trim();
      setState(() {
        _query = text.isEmpty
            ? null
            : (_query ?? const ProductQuery()).copyWith(searchText: text);
      });
    });
  }

  Future<void> _openFilters() async {
    if (_query == null) return;
    final updated = await showProductFilters(context, _query!);
    if (updated != null) setState(() => _query = updated);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Buscar productos…',
            border: InputBorder.none,
          ),
          onChanged: _onChanged,
        ),
        actions: [
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                setState(() => _query = null);
              },
            ),
          if (_query != null)
            IconButton(icon: const Icon(Icons.tune), onPressed: _openFilters),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final query = _query;
    if (query == null) {
      return const EmptyStateView(
        icon: Icons.search,
        title: 'Buscá en TodoClick',
        message: 'Escribí el nombre de un producto, marca o categoría.',
      );
    }

    final results = ref.watch(productsQueryProvider(query));
    return results.when(
      loading: () => const LoadingView(),
      error: (_, _) => ErrorStateView(
        message: 'No se pudo realizar la búsqueda.',
        onRetry: () => ref.invalidate(productsQueryProvider(query)),
      ),
      data: (products) => products.isEmpty
          ? const EmptyStateView(
              icon: Icons.search_off,
              title: 'Sin resultados',
              message: 'No encontramos productos para tu búsqueda.',
            )
          : ProductGrid(products: products),
    );
  }
}
