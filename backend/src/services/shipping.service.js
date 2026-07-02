/**
 * Servicio de envíos: arma el paquete (peso + dimensiones) a partir del carrito
 * y delega la cotización/seguimiento en el proveedor de logística configurado
 * (Correo Argentino en v1).
 *
 * Para cambiar/agregar proveedor, importar otro que cumpla el mismo contrato
 * `{ quote, track }` y seleccionarlo acá.
 */
import { env } from '../config/env.js';
import { productRepository } from '../repositories/product.repository.js';
import {
  buildImportPayload,
  provinceCodeFor,
} from './shipping/correoArgentinoMapper.js';
import { correoArgentino } from './shipping/correoArgentino.provider.js';
import { packageFromItems } from './shipping/shippingEstimation.js';

const provider = correoArgentino;

/** Resuelve las dimensiones reales (peso + caja) de un conjunto de líneas. */
async function packageForItems(items = []) {
  const resolved = [];
  for (const line of items) {
    const product = await productRepository.getById(line.productId);
    const d = product?.dimensions || {};
    resolved.push({
      weightGrams: Number(d.weightGrams) || undefined,
      widthCm: Number(d.widthCm) || undefined,
      heightCm: Number(d.heightCm) || undefined,
      lengthCm: Number(d.lengthCm) || undefined,
      quantity: Number(line.quantity) || 1,
    });
  }
  return packageFromItems(resolved);
}

export const shippingService = {
  /** Cotiza las opciones de envío para un destino y un carrito. */
  async quote({ postalCode, province, items = [] }) {
    const pkg = await packageForItems(items);
    const options = await provider.quote({
      postalCode,
      province,
      weightKg: pkg.weightKg,
      dimensions: pkg.dimensions,
    });
    return { weightKg: pkg.weightKg, options };
  },

  /** Seguimiento de un envío por código de tracking. */
  async track(trackingCode) {
    const events = await provider.track(trackingCode);
    return { trackingCode, events };
  },

  /** Sucursales de Correo Argentino de una provincia (nombre o código). */
  async agencies({ province, provinceCode, services } = {}) {
    const code =
      (provinceCode && String(provinceCode).toUpperCase()) ||
      provinceCodeFor(province);
    if (!code) return { provinceCode: null, agencies: [] };
    const agencies = await provider.agencies({ provinceCode: code, services });
    return { provinceCode: code, agencies };
  },

  /**
   * Importa un pedido a MiCorreo (alta de envío). Arma el body desde el pedido
   * + el remitente configurado (env) + las dimensiones reales del paquete.
   * `agency` (código de sucursal) es opcional, para envíos a sucursal.
   */
  async importOrder(order, { agency } = {}) {
    const pkg = await packageForItems(order?.items ?? []);
    const payload = buildImportPayload({
      order,
      sender: env.shipping.sender,
      agency,
      pkg,
    });
    const result = await provider.importShipping(payload);
    return { extOrderId: payload.extOrderId, ...result };
  },
};
