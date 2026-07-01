/**
 * Cálculos de precios PUROS (sin dependencias de Firebase/red), para que sean
 * fácilmente testeables y reutilizables entre el servicio de cupones y el de
 * pagos.
 */

export const round2 = (n) => Math.round(n * 100) / 100;

/** Precio final de un producto aplicando su descuento de oferta si corresponde. */
export function computeFinalPrice(product) {
  const price = Number(product.price) || 0;
  if (!product.isOnSale || !(Number(product.discountPercentage) > 0)) {
    return round2(price);
  }
  return round2(price * (1 - Number(product.discountPercentage) / 100));
}

/**
 * Monto de descuento de un cupón sobre un subtotal. Acotado a [0, subtotal] y,
 * para porcentuales, al tope `maxDiscountAmount` si está definido.
 */
export function computeCouponDiscount(coupon, subtotal) {
  let raw;
  switch (coupon.type) {
    case 'percentage':
      raw = subtotal * (Number(coupon.value) / 100);
      break;
    case 'fixed_amount':
      raw = Number(coupon.value);
      break;
    case 'free_shipping':
    default:
      raw = 0; // el envío se descuenta en el cálculo de logística
  }
  if (coupon.maxDiscountAmount != null) {
    raw = Math.min(raw, Number(coupon.maxDiscountAmount));
  }
  return Math.max(0, Math.min(raw, subtotal));
}
