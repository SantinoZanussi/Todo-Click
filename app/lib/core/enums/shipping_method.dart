/// Modalidades de entrega disponibles en el checkout.
///
/// Las opciones [homeDelivery] y [branchPickup] se cotizan contra el
/// proveedor de logística (Correo Argentino en v1). [storePickup] es retiro
/// en la sucursal propia de TodoClick y tiene costo cero.
enum ShippingMethod {
  /// Envío a domicilio del cliente.
  homeDelivery('home_delivery'),

  /// Retiro en una sucursal de Correo Argentino elegida por el cliente.
  branchPickup('branch_pickup'),

  /// Retiro en la sucursal física propia de TodoClick (sin costo).
  storePickup('store_pickup');

  const ShippingMethod(this.key);

  final String key;

  String get label => switch (this) {
    ShippingMethod.homeDelivery => 'Envío a domicilio',
    ShippingMethod.branchPickup => 'Retiro en sucursal de correo',
    ShippingMethod.storePickup => 'Retiro en tienda',
  };

  /// `true` si la modalidad requiere cotizar contra el proveedor de logística.
  bool get requiresQuote => this != ShippingMethod.storePickup;

  static ShippingMethod fromKey(String? key) {
    return ShippingMethod.values.firstWhere(
      (method) => method.key == key,
      orElse: () => ShippingMethod.homeDelivery,
    );
  }
}
