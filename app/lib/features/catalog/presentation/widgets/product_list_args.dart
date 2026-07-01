import '../../domain/entities/product_query.dart';

/// Argumentos de navegación para la pantalla de listado de productos.
///
/// Se pasan vía `extra` de go_router al navegar a `/products`.
class ProductListArgs {
  const ProductListArgs({required this.title, required this.query});

  final String title;
  final ProductQuery query;
}
