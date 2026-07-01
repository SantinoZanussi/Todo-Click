import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/product.dart';

/// DTO de [Product]: mapea el documento de Firestore a la entidad de dominio.
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.sku,
    required super.name,
    required super.description,
    required super.categoryId,
    required super.subcategoryId,
    required super.brandId,
    required super.price,
    required super.stock,
    required super.dimensions,
    required super.images,
    required super.isFeatured,
    required super.isOnSale,
    required super.discountPercentage,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    return ProductModel(
      id: doc.id,
      sku: d['sku'] as String? ?? '',
      name: d['name'] as String? ?? '',
      description: d['description'] as String? ?? '',
      categoryId: d['categoryId'] as String? ?? '',
      subcategoryId: d['subcategoryId'] as String? ?? '',
      brandId: d['brandId'] as String? ?? '',
      price: _toDouble(d['price']),
      stock: _toInt(d['stock']),
      dimensions: _dimensionsFrom(d['dimensions']),
      images: (d['images'] as List?)?.cast<String>() ?? const [],
      isFeatured: d['isFeatured'] as bool? ?? false,
      isOnSale: d['isOnSale'] as bool? ?? false,
      discountPercentage: _toDouble(d['discountPercentage']),
      isActive: d['isActive'] as bool? ?? true,
      createdAt: _toDate(d['createdAt']),
      updatedAt: _toDate(d['updatedAt']),
    );
  }

  static double _toDouble(Object? v) => (v as num?)?.toDouble() ?? 0;
  static int _toInt(Object? v) => (v as num?)?.toInt() ?? 0;

  static DateTime _toDate(Object? v) =>
      v is Timestamp ? v.toDate() : DateTime.now();

  static ProductDimensions _dimensionsFrom(Object? v) {
    final m = v is Map ? v : const {};
    return ProductDimensions(
      weightGrams: _toDouble(m['weightGrams']),
      widthCm: _toDouble(m['widthCm']),
      heightCm: _toDouble(m['heightCm']),
      lengthCm: _toDouble(m['lengthCm']),
    );
  }
}
