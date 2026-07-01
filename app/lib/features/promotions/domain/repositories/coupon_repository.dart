import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/coupon_validation.dart';

/// Valida cupones contra el backend (la lógica vive server-side por seguridad).
abstract interface class CouponRepository {
  Future<Either<Failure, CouponValidation>> validate({
    required String code,
    required double subtotal,
  });
}
