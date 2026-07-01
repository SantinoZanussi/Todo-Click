import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/discount_type.dart';
import '../../domain/entities/promotion.dart';

/// DTO de [Promotion] para leer la colección `promociones`.
class PromotionModel extends Promotion {
  const PromotionModel({
    required super.id,
    required super.title,
    required super.type,
    required super.value,
    required super.isActive,
    required super.validFrom,
    required super.validUntil,
    super.subtitle,
    super.bannerUrl,
    super.targetCategoryIds,
    super.targetProductIds,
    super.order,
  });

  factory PromotionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    return PromotionModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      subtitle: d['subtitle'] as String?,
      bannerUrl: d['bannerUrl'] as String?,
      type: DiscountType.fromKey(d['type'] as String?),
      value: (d['value'] as num?)?.toDouble() ?? 0,
      isActive: d['isActive'] as bool? ?? true,
      validFrom: _dt(d['validFrom']),
      validUntil: _dt(d['validUntil']),
      targetCategoryIds:
          (d['targetCategoryIds'] as List?)?.cast<String>() ?? const [],
      targetProductIds:
          (d['targetProductIds'] as List?)?.cast<String>() ?? const [],
      order: (d['order'] as num?)?.toInt() ?? 0,
    );
  }

  static DateTime _dt(Object? v) =>
      v is Timestamp ? v.toDate() : DateTime.now();
}
