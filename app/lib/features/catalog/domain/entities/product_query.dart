import 'package:equatable/equatable.dart';

/// Criterio de ordenamiento de resultados del catálogo.
enum ProductSort {
  relevance('Relevancia'),
  priceAsc('Menor precio'),
  priceDesc('Mayor precio'),
  newest('Más nuevos'),
  discount('Mayor descuento');

  const ProductSort(this.label);
  final String label;
}

/// Parámetros de búsqueda/filtrado del catálogo.
///
/// Es un value object inmutable que viaja desde la UI (pantalla de resultados
/// + filtros) hasta el repositorio. Los filtros primarios (categoría, marca,
/// texto) se resuelven server-side en Firestore; los secundarios (rango de
/// precio, disponibilidad) se afinan en cliente para evitar combinaciones de
/// índices excesivas.
class ProductQuery extends Equatable {
  const ProductQuery({
    this.categoryId,
    this.subcategoryId,
    this.brandId,
    this.searchText,
    this.minPrice,
    this.maxPrice,
    this.inStockOnly = false,
    this.onSaleOnly = false,
    this.sort = ProductSort.relevance,
    this.limit = 60,
  });

  final String? categoryId;
  final String? subcategoryId;
  final String? brandId;
  final String? searchText;
  final double? minPrice;
  final double? maxPrice;
  final bool inStockOnly;
  final bool onSaleOnly;
  final ProductSort sort;
  final int limit;

  bool get hasText => (searchText?.trim().isNotEmpty ?? false);

  /// `true` si hay algún filtro secundario activo (para mostrar el badge).
  bool get hasActiveFilters =>
      minPrice != null ||
      maxPrice != null ||
      inStockOnly ||
      onSaleOnly ||
      brandId != null ||
      sort != ProductSort.relevance;

  ProductQuery copyWith({
    String? categoryId,
    String? subcategoryId,
    String? brandId,
    String? searchText,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
    bool? onSaleOnly,
    ProductSort? sort,
    int? limit,
    bool clearBrand = false,
    bool clearPrices = false,
  }) {
    return ProductQuery(
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      brandId: clearBrand ? null : (brandId ?? this.brandId),
      searchText: searchText ?? this.searchText,
      minPrice: clearPrices ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrices ? null : (maxPrice ?? this.maxPrice),
      inStockOnly: inStockOnly ?? this.inStockOnly,
      onSaleOnly: onSaleOnly ?? this.onSaleOnly,
      sort: sort ?? this.sort,
      limit: limit ?? this.limit,
    );
  }

  @override
  List<Object?> get props => [
    categoryId,
    subcategoryId,
    brandId,
    searchText,
    minPrice,
    maxPrice,
    inStockOnly,
    onSaleOnly,
    sort,
    limit,
  ];
}
