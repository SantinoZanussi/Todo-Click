/**
 * Lógica de validación de cupones.
 *
 * Es la fuente de verdad: el cliente NO puede leer la colección `cupones`
 * (las reglas de Firestore lo impiden), así que el descuento se calcula acá y
 * se vuelve a validar al confirmar el pago (Fase 8) para evitar manipulación.
 */
import { couponRepository } from '../repositories/coupon.repository.js';
import { computeCouponDiscount } from '../shared/utils/pricing.js';

/** Convierte un valor de Firestore (Timestamp | string | Date) a Date. */
function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === 'function') return value.toDate();
  return new Date(value);
}

export const couponService = {
  /**
   * Valida un cupón contra un subtotal.
   * @returns {{valid:boolean, message:string, code?:string, type?:string, discount?:number, freeShipping?:boolean}}
   */
  async validate(rawCode, subtotal) {
    const code = String(rawCode ?? '').trim().toUpperCase();
    if (!code) return { valid: false, message: 'Ingresá un código de cupón.' };

    const coupon = await couponRepository.getByCode(code);
    if (!coupon || coupon.isActive === false) {
      return { valid: false, message: 'El cupón no existe o no está activo.' };
    }

    const now = new Date();
    const from = toDate(coupon.validFrom);
    const until = toDate(coupon.validUntil);
    if (from && now < from) {
      return { valid: false, message: 'El cupón todavía no está vigente.' };
    }
    if (until && now > until) {
      return { valid: false, message: 'El cupón está vencido.' };
    }
    if (
      coupon.usageLimit != null &&
      (coupon.usedCount ?? 0) >= coupon.usageLimit
    ) {
      return { valid: false, message: 'El cupón alcanzó su límite de uso.' };
    }
    const min = Number(coupon.minPurchaseAmount ?? 0);
    if (subtotal < min) {
      return {
        valid: false,
        message: `Requiere una compra mínima de $${min.toLocaleString('es-AR')}.`,
      };
    }

    const discount = computeCouponDiscount(coupon, subtotal);
    return {
      valid: true,
      code,
      type: coupon.type,
      discount,
      freeShipping: coupon.type === 'free_shipping',
      message: 'Cupón aplicado correctamente.',
    };
  },
};
