/**
 * Logger centralizado (pino).
 *
 * En desarrollo usa `pino-pretty` para salida legible; en producción emite
 * JSON estructurado, ideal para Cloud Run / agregadores de logs.
 */
import pino from 'pino';

import { env } from '../../config/env.js';

export const logger = pino({
  level: env.isProd ? 'info' : 'debug',
  transport: env.isProd
    ? undefined
    : {
        target: 'pino-pretty',
        options: { colorize: true, translateTime: 'SYS:HH:MM:ss' },
      },
});
