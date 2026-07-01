/// Tipo de descuento aplicado por un cupón o una promoción.
enum DiscountType {
  /// Descuento porcentual sobre el subtotal (p. ej. 15%).
  percentage('percentage'),

  /// Descuento de monto fijo (p. ej. $2000 ARS).
  fixedAmount('fixed_amount'),

  /// Envío gratis.
  freeShipping('free_shipping');

  const DiscountType(this.key);

  final String key;

  String get label => switch (this) {
    DiscountType.percentage => 'Porcentaje',
    DiscountType.fixedAmount => 'Monto fijo',
    DiscountType.freeShipping => 'Envío gratis',
  };

  static DiscountType fromKey(String? key) {
    return DiscountType.values.firstWhere(
      (type) => type.key == key,
      orElse: () => DiscountType.percentage,
    );
  }
}
