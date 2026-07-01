/**
 * Configuración de Cloudinary y firma de uploads.
 *
 * Patrón de subida segura: el backend FIRMA los parámetros y la app sube el
 * archivo directamente a Cloudinary con esa firma. Así el `api_secret` nunca
 * sale del servidor y no se proxean los bytes de la imagen por la API.
 */
import { v2 as cloudinary } from 'cloudinary';

import { env } from './env.js';

cloudinary.config({
  cloud_name: env.cloudinary.cloudName,
  api_key: env.cloudinary.apiKey,
  api_secret: env.cloudinary.apiSecret,
  secure: true,
});

/** Devuelve los parámetros firmados para un upload directo desde el cliente. */
export function signUpload({ folder } = {}) {
  const timestamp = Math.round(Date.now() / 1000);
  const uploadFolder = folder || env.cloudinary.uploadFolder;
  const signature = cloudinary.utils.api_sign_request(
    { timestamp, folder: uploadFolder },
    env.cloudinary.apiSecret,
  );
  return {
    timestamp,
    signature,
    apiKey: env.cloudinary.apiKey,
    cloudName: env.cloudinary.cloudName,
    folder: uploadFolder,
  };
}

export { cloudinary };
