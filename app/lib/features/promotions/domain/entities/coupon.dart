import 'package:equatable/equatable.dart';

import '../../../../core/enums/discount_type.dart';

/// Cupón de descuento canjeable en el checkout mediante un código.
///
/// La validación final (vigencia, usos restantes, monto mínimo) SIEMPRE se
/// hace en el backend al confirmar la compra, para que el cliente no pueda
/// forzar descuentos manipulando el cliente.
class Coupon extends Equatable {
  const Coupon({
    required this.id,
    required this.code,
    required this.type,
    required this.value,
    required this.isActive,
    required this.validFrom,
    required this.validUntil,
    this.minPurchaseAmount = 0,
    this.maxDiscountAmount,
    this.usageLimit,
    this.usedCount = 0,
    this.description,
  });

  final String id;

  /// Código que ingresa el usuario (normalizado en MAYÚSCULAS, p. ej. `BIENVENIDO10`).
  final String code;

  final DiscountType type;

  /// Valor del descuento: porcentaje (0-100) o monto fijo en ARS según [type].
  final double value;

  final bool isActive;
  final DateTime validFrom;
  final DateTime validUntil;

  /// Monto mínimo de compra para que aplique el cupón.
  final double minPurchaseAmount;

  /// Tope máximo de descuento en ARS (para cupones porcentuales).
  final double? maxDiscountAmount;

  /// Límite total de usos del cupón (`null` = ilimitado).
  final int? usageLimit;

  /// Usos consumidos hasta el momento.
  final int usedCount;

  final String? description;

  /// `true` si el cupón está vigente en [now] (sin contemplar monto mínimo).
  bool isValidAt(DateTime now) {
    if (!isActive) return false;
    if (now.isBefore(validFrom) || now.isAfter(validUntil)) return false;
    if (usageLimit != null && usedCount >= usageLimit!) return false;
    return true;
  }

  /// Calcula el descuento a aplicar sobre [amount] (no negativo, acotado).
  double discountFor(double amount) {
    if (amount < minPurchaseAmount) return 0;
    final raw = switch (type) {
      DiscountType.percentage => amount * (value / 100),
      DiscountType.fixedAmount => value,
      DiscountType.freeShipping => 0, // el envío se descuenta aparte
    };
    final capped = maxDiscountAmount != null
        ? raw.clamp(0, maxDiscountAmount!).toDouble()
        : raw;
    // Nunca descontar más que el propio monto.
    return capped.clamp(0, amount).toDouble();
  }

  @override
  List<Object?> get props => [
    id,
    code,
    type,
    value,
    isActive,
    validFrom,
    validUntil,
    minPurchaseAmount,
    maxDiscountAmount,
    usageLimit,
    usedCount,
    description,
  ];
}
