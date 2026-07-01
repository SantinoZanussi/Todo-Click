import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/enums/discount_type.dart';
import '../../domain/entities/coupon.dart';

/// DTO de [Coupon] para leer la colección `cupones` (solo admin).
class CouponModel extends Coupon {
  const CouponModel({
    required super.id,
    required super.code,
    required super.type,
    required super.value,
    required super.isActive,
    required super.validFrom,
    required super.validUntil,
    super.minPurchaseAmount,
    super.maxDiscountAmount,
    super.usageLimit,
    super.usedCount,
    super.description,
  });

  factory CouponModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? const {};
    return CouponModel(
      id: doc.id,
      code: d['code'] as String? ?? doc.id,
      type: DiscountType.fromKey(d['type'] as String?),
      value: (d['value'] as num?)?.toDouble() ?? 0,
      isActive: d['isActive'] as bool? ?? true,
      validFrom: _dt(d['validFrom']),
      validUntil: _dt(d['validUntil']),
      minPurchaseAmount: (d['minPurchaseAmount'] as num?)?.toDouble() ?? 0,
      maxDiscountAmount: (d['maxDiscountAmount'] as num?)?.toDouble(),
      usageLimit: (d['usageLimit'] as num?)?.toInt(),
      usedCount: (d['usedCount'] as num?)?.toInt() ?? 0,
      description: d['description'] as String?,
    );
  }

  static DateTime _dt(Object? v) =>
      v is Timestamp ? v.toDate() : DateTime.now();
}
