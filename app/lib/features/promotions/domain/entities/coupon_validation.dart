import 'package:equatable/equatable.dart';

/// Resultado de validar un cupón contra el backend.
class CouponValidation extends Equatable {
  const CouponValidation({
    required this.code,
    required this.discount,
    required this.message,
    this.freeShipping = false,
  });

  final String code;

  /// Monto de descuento en ARS a aplicar sobre el subtotal.
  final double discount;

  /// Si el cupón otorga envío gratis (se aplica en el cálculo de logística).
  final bool freeShipping;

  final String message;

  @override
  List<Object?> get props => [code, discount, freeShipping, message];
}
