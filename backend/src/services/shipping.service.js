/**
 * Servicio de envíos: orquesta el cálculo de peso del pedido y delega en el
 * proveedor de logística configurado (Correo Argentino en v1).
 *
 * Para cambiar/agregar proveedor, importar otro que cumpla el mismo contrato
 * `{ quote, track }` y seleccionarlo acá.
 */
import { productRepository } from '../repositories/product.repository.js';
import { correoArgentino } from './shipping/correoArgentino.provider.js';

const provider = correoArgentino;

const DEFAULT_ITEM_GRAMS = 500;

export const shippingService = {
  /** Cotiza las opciones de envío para un destino y un carrito. */
  async quote({ postalCode, province, items = [] }) {
    let totalGrams = 0;
    for (const line of items) {
      const product = await productRepository.getById(line.productId);
      const grams = Number(product?.dimensions?.weightGrams) || DEFAULT_ITEM_GRAMS;
      totalGrams += grams * (Number(line.quantity) || 1);
    }
    const weightKg = Math.max(0.1, totalGrams / 1000);

    const options = await provider.quote({ postalCode, province, weightKg });
    return { weightKg: Math.round(weightKg * 100) / 100, options };
  },

  /** Seguimiento de un envío por código de tracking. */
  async track(trackingCode) {
    const events = await provider.track(trackingCode);
    return { trackingCode, events };
  },
};
