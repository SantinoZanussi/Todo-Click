import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/brand.dart';

/// DTO de [Brand].
class BrandModel extends Brand {
  const BrandModel({
    required super.id,
    required super.name,
    required super.slug,
    super.logoUrl,
    super.isActive,
  });

  factory BrandModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    return BrandModel(
      id: doc.id,
      name: d['name'] as String? ?? '',
      slug: d['slug'] as String? ?? doc.id,
      logoUrl: d['logoUrl'] as String?,
      isActive: d['isActive'] as bool? ?? true,
    );
  }
}
