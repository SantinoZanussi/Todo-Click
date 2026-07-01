import 'package:equatable/equatable.dart';

/// Marca de un producto.
///
/// Gestionable desde el panel admin (Fase 7). Se referencia por `id` desde
/// [Product.brandId] y permite filtrar el catálogo por marca.
class Brand extends Equatable {
  const Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final bool isActive;

  Brand copyWith({
    String? id,
    String? name,
    String? slug,
    String? logoUrl,
    bool? isActive,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, logoUrl, isActive];
}
