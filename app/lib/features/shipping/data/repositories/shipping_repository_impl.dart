import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../../core/enums/enums.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/shipping_option.dart';
import '../../domain/entities/tracking_event.dart';
import '../../domain/repositories/shipping_repository.dart';

/// Implementación que consume el API de envíos del backend (`/api/shipping`).
class ShippingRepositoryImpl implements ShippingRepository {
  const ShippingRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, List<ShippingOption>>> quote({
    required String province,
    required String postalCode,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/shipping/quote',
        data: {'province': province, 'postalCode': postalCode, 'items': items},
      );
      final options = (res.data?['options'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => _optionFrom(Map<String, dynamic>.from(m)))
          .toList();
      return Right(options);
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TrackingEvent>>> track(
    String trackingCode,
  ) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/shipping/track/$trackingCode',
      );
      final events = (res.data?['events'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => TrackingEvent.fromJson(Map<String, dynamic>.from(m)))
          .toList();
      return Right(events);
    } on DioException catch (e) {
      return Left(ServerFailure(_message(e)));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  ShippingOption _optionFrom(Map<String, dynamic> m) => ShippingOption(
    method: ShippingMethod.fromKey(m['method'] as String?),
    label: m['label'] as String? ?? 'Envío',
    cost: (m['cost'] as num?)?.toDouble() ?? 0,
    estimatedDays: (m['estimatedDays'] as num?)?.toInt() ?? 0,
    carrier: m['carrier'] as String? ?? 'Correo Argentino',
  );

  String _message(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      return data['error']['message'] as String? ?? 'Error de envío';
    }
    return 'No se pudo calcular el envío. Intentá de nuevo.';
  }
}
