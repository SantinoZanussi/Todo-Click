/**
 * Controlador de envíos (Correo Argentino).
 */
import { shippingService } from '../services/shipping.service.js';

export const shippingController = {
  async quote(req, res) {
    const { postalCode, province, items } = req.body;
    res.json(
      await shippingService.quote({
        postalCode,
        province,
        items: items ?? [],
      }),
    );
  },

  async track(req, res) {
    res.json(await shippingService.track(req.params.code));
  },
};
