import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/coupon_validation.dart';
import '../../domain/repositories/coupon_repository.dart';

/// Implementación que consulta `POST /api/coupons/validate` en el backend.
class CouponRepositoryImpl implements CouponRepository {
  const CouponRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, CouponValidation>> validate({
    required String code,
    required double subtotal,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/coupons/validate',
        data: {'code': code, 'subtotal': subtotal},
      );
      final data = res.data ?? const {};
      final isValid = data['valid'] == true;
      final message = data['message'] as String? ?? '';
      if (!isValid) {
        return Left(
          ValidationFailure(message.isEmpty ? 'Cupón inválido' : message),
        );
      }
      return Right(
        CouponValidation(
          code: data['code'] as String? ?? code.toUpperCase(),
          discount: (data['discount'] as num?)?.toDouble() ?? 0,
          freeShipping: data['freeShipping'] == true,
          message: message,
        ),
      );
    } on DioException catch (e) {
      final msg = e.response?.data is Map
          ? (e.response?.data['error']?['message'] as String?)
          : null;
      return Left(
        ServerFailure(msg ?? 'No se pudo validar el cupón. Intentá de nuevo.'),
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
