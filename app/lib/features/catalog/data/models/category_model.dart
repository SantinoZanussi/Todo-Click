import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/category.dart';

/// DTO de [Category] con sus subcategorías embebidas.
class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.name,
    required super.slug,
    required super.subcategories,
    super.iconName,
    super.imageUrl,
    super.order,
    super.isActive,
    super.isFeatured,
  });

  factory CategoryModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    final subs = (d['subcategories'] as List?) ?? const [];
    return CategoryModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      slug: d['slug'] as String? ?? doc.id,
      iconName: d['iconName'] as String?,
      imageUrl: d['imageUrl'] as String?,
      order: (d['order'] as num?)?.toInt() ?? 0,
      isActive: d['isActive'] as bool? ?? true,
      isFeatured: d['isFeatured'] as bool? ?? false,
      subcategories: subs
          .whereType<Map>()
          .map(
            (s) => Subcategory(
              id: s['id'] as String? ?? '',
              name: s['name'] as String? ?? '',
              slug: s['slug'] as String? ?? '',
              imageUrl: s['imageUrl'] as String?,
              order: (s['order'] as num?)?.toInt() ?? 0,
              isActive: s['isActive'] as bool? ?? true,
            ),
          )
          .toList(),
    );
  }
}
