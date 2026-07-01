import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/checkout_result.dart';

/// Consume el API de pagos del backend (`/api/payments`).
class PaymentRepository {
  const PaymentRepository(this._dio);

  final Dio _dio;

  /// Crea el pedido + la preferencia de Mercado Pago.
  Future<Either<Failure, CheckoutResult>> createCheckout(
    Map<String, dynamic> body,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/payments/checkout',
        data: body,
      );
      return Right(CheckoutResult.fromJson(res.data ?? const {}));
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  /// Consulta el estado de un pedido (sirve también para invitados).
  Future<Either<Failure, OrderStatusResult>> getOrderStatus(
    String orderId,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/payments/status/$orderId',
      );
      return Right(OrderStatusResult.fromJson(res.data ?? const {}));
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['message'] as String? ?? 'Error de pago';
    }
    return 'No se pudo procesar el pago. Intentá de nuevo.';
  }
}
