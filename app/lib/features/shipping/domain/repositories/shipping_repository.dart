import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/shipping_option.dart';
import '../entities/tracking_event.dart';

/// Contrato de logística. La implementación (backend → Correo Argentino) se
/// puede reemplazar por otra (Andreani) sin tocar la presentación.
abstract interface class ShippingRepository {
  /// Cotiza las opciones de envío para un destino y un carrito.
  Future<Either<Failure, List<ShippingOption>>> quote({
    required String province,
    required String postalCode,
    required List<Map<String, dynamic>> items,
  });

  /// Seguimiento de un envío por código de tracking.
  Future<Either<Failure, List<TrackingEvent>>> track(String trackingCode);
}
