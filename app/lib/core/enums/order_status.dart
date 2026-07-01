/// Estados posibles de un pedido en TodoClick.
///
/// El ciclo de vida normal de un pedido es:
/// [pending] → [paymentPending] → [paid] → [preparing] → [dispatched]
/// → [inTransit] → [delivered]
///
/// En cualquier punto previo a [delivered] un pedido puede pasar a
/// [cancelled]; y un pedido ya pagado puede terminar en [refunded].
///
/// El valor que se persiste en Firestore es el [key] (string estable en
/// inglés). NUNCA persistir el índice del enum: si reordenamos los valores
/// la base de datos quedaría inconsistente.
enum OrderStatus {
  /// Pedido creado pero el usuario todavía no inició el pago.
  pending('pending'),

  /// Preferencia de Mercado Pago creada; esperando confirmación del pago.
  paymentPending('payment_pending'),

  /// Pago aprobado y acreditado (confirmado vía webhook de Mercado Pago).
  paid('paid'),

  /// El equipo está preparando / empaquetando el pedido.
  preparing('preparing'),

  /// Pedido despachado: entregado al correo / listo para envío.
  dispatched('dispatched'),

  /// En camino al destino (tracking activo de Correo Argentino).
  inTransit('in_transit'),

  /// Entregado al cliente.
  delivered('delivered'),

  /// Pedido cancelado (por el cliente o el admin).
  cancelled('cancelled'),

  /// Pago reembolsado al cliente.
  refunded('refunded');

  const OrderStatus(this.key);

  /// Clave estable persistida en Firestore.
  final String key;

  /// Etiqueta legible en español (para mostrar en UI).
  String get label => switch (this) {
    OrderStatus.pending => 'Pendiente',
    OrderStatus.paymentPending => 'Pago pendiente',
    OrderStatus.paid => 'Pagado',
    OrderStatus.preparing => 'Preparando',
    OrderStatus.dispatched => 'Despachado',
    OrderStatus.inTransit => 'En tránsito',
    OrderStatus.delivered => 'Entregado',
    OrderStatus.cancelled => 'Cancelado',
    OrderStatus.refunded => 'Reembolsado',
  };

  /// `true` si el pedido llegó a un estado final (no admite más transiciones).
  bool get isFinal =>
      this == OrderStatus.delivered ||
      this == OrderStatus.cancelled ||
      this == OrderStatus.refunded;

  /// `true` si el pedido ya fue pagado (o pasó por un estado posterior al pago).
  bool get isPaid => const {
    OrderStatus.paid,
    OrderStatus.preparing,
    OrderStatus.dispatched,
    OrderStatus.inTransit,
    OrderStatus.delivered,
    OrderStatus.refunded,
  }.contains(this);

  /// Reconstruye el enum desde la clave persistida.
  ///
  /// Si la clave es desconocida (p. ej. dato corrupto o versión futura)
  /// devuelve [OrderStatus.pending] como valor seguro por defecto.
  static OrderStatus fromKey(String? key) {
    return OrderStatus.values.firstWhere(
      (status) => status.key == key,
      orElse: () => OrderStatus.pending,
    );
  }
}
