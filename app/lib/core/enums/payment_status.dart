/// Estado del pago de un pedido, alineado con los estados de Mercado Pago.
///
/// Mercado Pago reporta el estado del pago vía webhook con valores como
/// `approved`, `pending`, `rejected`, etc. Mapeamos esos valores a este enum
/// para no acoplar el dominio a strings sueltos del proveedor.
enum PaymentStatus {
  /// Pago aún no iniciado.
  none('none'),

  /// Pago en proceso / pendiente de acreditación.
  pending('pending'),

  /// Pago aprobado y acreditado.
  approved('approved'),

  /// Pago autorizado pero no capturado todavía.
  authorized('authorized'),

  /// En revisión / mediación.
  inProcess('in_process'),

  /// Pago rechazado.
  rejected('rejected'),

  /// Pago cancelado.
  cancelled('cancelled'),

  /// Pago devuelto al comprador.
  refunded('refunded'),

  /// Contracargo realizado por el comprador.
  chargedBack('charged_back');

  const PaymentStatus(this.key);

  final String key;

  String get label => switch (this) {
    PaymentStatus.none => 'Sin pago',
    PaymentStatus.pending => 'Pendiente',
    PaymentStatus.approved => 'Aprobado',
    PaymentStatus.authorized => 'Autorizado',
    PaymentStatus.inProcess => 'En proceso',
    PaymentStatus.rejected => 'Rechazado',
    PaymentStatus.cancelled => 'Cancelado',
    PaymentStatus.refunded => 'Reembolsado',
    PaymentStatus.chargedBack => 'Contracargo',
  };

  /// Mapea el `status` crudo que devuelve Mercado Pago a este enum.
  static PaymentStatus fromKey(String? key) {
    return PaymentStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => PaymentStatus.none,
    );
  }
}
