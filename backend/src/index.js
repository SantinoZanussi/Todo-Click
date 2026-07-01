/**
 * Punto de entrada del servidor.
 *
 * Arranca el HTTP server y registra manejadores de apagado ordenado
 * (graceful shutdown) y de errores no capturados.
 */
import { createApp } from './app.js';
import { env } from './config/env.js';
import { logger } from './shared/utils/logger.js';

const app = createApp();

const server = app.listen(env.port, () => {
  logger.info(`🚀 TodoClick API escuchando en :${env.port} [${env.nodeEnv}]`);
});

// Apagado ordenado (Cloud Run envía SIGTERM al desescalar).
for (const signal of ['SIGTERM', 'SIGINT']) {
  process.on(signal, () => {
    logger.info(`${signal} recibido — cerrando servidor...`);
    server.close(() => process.exit(0));
  });
}

process.on('unhandledRejection', (reason) => {
  logger.error({ reason }, 'Unhandled promise rejection');
});
