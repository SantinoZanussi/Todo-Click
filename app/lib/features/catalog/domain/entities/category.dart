import 'package:equatable/equatable.dart';

/// Subcategoría dentro de una [Category].
///
/// Se modela como sub-documento embebido (array `subcategories` dentro del
/// documento de la categoría) porque la cantidad de subcategorías por
/// categoría es acotada y siempre se leen juntas.
class Subcategory extends Equatable {
  const Subcategory({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    this.order = 0,
    this.isActive = true,
  });

  final String id;
  final String name;

  /// Slug URL-friendly (p. ej. `remeras`). Único dentro de la categoría.
  final String slug;

  final String? imageUrl;

  /// Orden de visualización (menor = primero).
  final int order;
  final bool isActive;

  @override
  List<Object?> get props => [id, name, slug, imageUrl, order, isActive];
}

/// Categoría de productos (nivel superior del árbol de catálogo).
///
/// Las categorías son **dinámicas**: el admin puede crear/editar/desactivar
/// categorías y subcategorías desde el panel (Fase 7). El set inicial estilo
/// Shein se siembra desde `firebase/seed/categories.json`.
class Category extends Equatable {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.subcategories,
    this.iconName,
    this.imageUrl,
    this.order = 0,
    this.isActive = true,
    this.isFeatured = false,
  });

  final String id;
  final String name;

  /// Slug URL-friendly único (p. ej. `moda-mujer`).
  final String slug;

  final List<Subcategory> subcategories;

  /// Nombre del ícono (Material/custom) para mostrar en el grid de categorías.
  final String? iconName;

  /// Imagen de portada de la categoría (Cloudinary).
  final String? imageUrl;

  final int order;
  final bool isActive;

  /// Si aparece destacada en el home.
  final bool isFeatured;

  Category copyWith({
    String? id,
    String? name,
    String? slug,
    List<Subcategory>? subcategories,
    String? iconName,
    String? imageUrl,
    int? order,
    bool? isActive,
    bool? isFeatured,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      subcategories: subcategories ?? this.subcategories,
      iconName: iconName ?? this.iconName,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    subcategories,
    iconName,
    imageUrl,
    order,
    isActive,
    isFeatured,
  ];
}
