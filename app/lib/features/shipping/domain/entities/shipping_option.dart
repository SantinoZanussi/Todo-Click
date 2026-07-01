import 'package:equatable/equatable.dart';

import '../../../../core/enums/shipping_method.dart';

/// Una opción de envío cotizada para mostrar en el checkout.
///
/// Es el resultado de consultar al proveedor de logística (Correo Argentino)
/// para un carrito y un código postal dados. El backend calcula estas opciones
/// y la app solo las muestra; el cliente elige una.
class ShippingOption extends Equatable {
  const ShippingOption({
    required this.method,
    required this.label,
    required this.cost,
    required this.estimatedDays,
    this.carrier = 'Correo Argentino',
    this.branchId,
    this.branchName,
    this.branchAddress,
  });

  final ShippingMethod method;

  /// Etiqueta a mostrar (p. ej. "Envío a domicilio — Correo Argentino").
  final String label;

  /// Costo en ARS.
  final double cost;

  /// Tiempo estimado de entrega en días hábiles.
  final int estimatedDays;

  final String carrier;

  // Datos de sucursal (solo para retiro en sucursal de correo).
  final String? branchId;
  final String? branchName;
  final String? branchAddress;

  bool get isFree => cost <= 0;

  @override
  List<Object?> get props => [
    method,
    label,
    cost,
    estimatedDays,
    carrier,
    branchId,
    branchName,
    branchAddress,
  ];
}
