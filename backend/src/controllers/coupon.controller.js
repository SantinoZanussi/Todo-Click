/**
 * Controlador de cupones.
 */
import { couponService } from '../services/coupon.service.js';

export const couponController = {
  async validate(req, res) {
    const { code, subtotal } = req.body;
    const result = await couponService.validate(code, Number(subtotal) || 0);
    res.json(result);
  },
};
