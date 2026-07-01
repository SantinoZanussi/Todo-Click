/**
 * Controlador de autenticación.
 *
 * Trabaja sobre `req.user` (ya validado por `verifyFirebaseToken`).
 */
import { userRepository } from '../repositories/user.repository.js';

export const authController = {
  /** Devuelve la identidad del token + el perfil de Firestore. */
  async me(req, res) {
    const profile = await userRepository.getById(req.user.uid);
    res.json({
      uid: req.user.uid,
      email: req.user.email,
      role: req.user.role,
      profile,
    });
  },
};
