import 'package:equatable/equatable.dart';

/// Dirección de envío / facturación de un cliente.
///
/// Entidad compartida: la usan `profile` (libreta de direcciones),
/// `checkout` (datos del envío) y `orders` (snapshot de la dirección al
/// momento de la compra). Los campos reflejan exactamente lo que pide el
/// formulario de checkout del requerimiento.
class Address extends Equatable {
  const Address({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.province,
    required this.city,
    required this.street,
    required this.postalCode,
    this.id,
    this.apartment,
    this.notes,
    this.isDefault = false,
  });

  /// Id del documento (cuando se guarda en la libreta de direcciones).
  /// Es `null` para una dirección de checkout de invitado.
  final String? id;

  final String firstName;
  final String lastName;
  final String email;
  final String phone;

  /// Provincia argentina (p. ej. "Buenos Aires", "Córdoba").
  final String province;

  /// Localidad / ciudad.
  final String city;

  /// Calle y altura.
  final String street;

  /// Piso / departamento (opcional).
  final String? apartment;

  /// Código postal (CPA de Correo Argentino, p. ej. "C1414").
  final String postalCode;

  /// Notas para el repartidor (opcional).
  final String? notes;

  /// Si es la dirección predeterminada del usuario.
  final bool isDefault;

  /// Nombre completo (para mostrar).
  String get fullName => '$firstName $lastName';

  Address copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? province,
    String? city,
    String? street,
    String? apartment,
    String? postalCode,
    String? notes,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      province: province ?? this.province,
      city: city ?? this.city,
      street: street ?? this.street,
      apartment: apartment ?? this.apartment,
      postalCode: postalCode ?? this.postalCode,
      notes: notes ?? this.notes,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [
    id,
    firstName,
    lastName,
    email,
    phone,
    province,
    city,
    street,
    apartment,
    postalCode,
    notes,
    isDefault,
  ];
}
