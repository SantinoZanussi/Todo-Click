import 'package:equatable/equatable.dart';

/// Sucursal de Correo Argentino donde el cliente puede retirar su pedido.
///
/// La devuelve el backend (`GET /api/shipping/agencies`) a partir de la API
/// MiCorreo, para el retiro en sucursal (branch_pickup).
class ShippingAgency extends Equatable {
  const ShippingAgency({
    required this.code,
    required this.name,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    this.phone,
  });

  /// Código de sucursal (p. ej. `B0107`). Es el `agency` para el despacho.
  final String code;
  final String name;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final String? phone;

  factory ShippingAgency.fromJson(Map<String, dynamic> json) => ShippingAgency(
    code: json['code'] as String? ?? '',
    name: json['name'] as String? ?? 'Sucursal',
    address: json['address'] as String?,
    city: json['city'] as String?,
    province: json['province'] as String?,
    postalCode: json['postalCode'] as String?,
    phone: json['phone'] as String?,
  );

  /// Texto corto para el selector: "Nombre · Localidad".
  String get shortLabel => city == null || city!.isEmpty ? name : '$name · $city';

  @override
  List<Object?> get props => [
    code,
    name,
    address,
    city,
    province,
    postalCode,
    phone,
  ];
}
