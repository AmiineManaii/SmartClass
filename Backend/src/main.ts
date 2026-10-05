import type { Server } from 'node:http';
import { getEnv } from './config/env.js';
import { logger } from './shared/infrastructure/logger.js';
import { disconnectPrisma } from './shared/infrastructure/prisma.js';
import { createApp } from './app.js';

const startServer = (): void => {
  const env = getEnv();
  const app = createApp();

  const server: Server = app.listen(env.PORT, () => {
    logger.info(
      {
        port: env.PORT,
        nodeEnv: env.NODE_ENV,
        nodeVersion: process.version,
      },
      `🚀 SmartClass API server running on port ${env.PORT}`,
    );
  });

  // Graceful shutdown handling
  let isShuttingDown = false;

  const handleShutdown = async (signal: string): Promise<void> => {
    if (isShuttingDown) return;
    isShuttingDown = true;

    logger.info(`Received ${signal}, initiating graceful shutdown...`);

    // Force shutdown timeout after 10s
    const forceExitTimer = setTimeout(() => {
      logger.error('Graceful shutdown timed out (10s), forcing process termination.');
      process.exit(1);
    }, 10000);
    forceExitTimer.unref();

    try {
      // 1. Stop receiving new connections and drain active ones
      await new Promise<void>((resolve, reject) => {
        server.close((err) => {
          if (err) return reject(err);
          resolve();
        });
      });
      logger.info('HTTP server closed successfully.');

      // 2. Disconnect database connections
      await disconnectPrisma();
      logger.info('Database connections closed.');

      logger.info('Graceful shutdown completed.');
      process.exit(0);
    } catch (err) {
      logger.error({ err }, 'Error occurred during graceful shutdown.');
      process.exit(1);
    }
  };

  process.on('SIGTERM', () => void handleShutdown('SIGTERM'));
  process.on('SIGINT', () => void handleShutdown('SIGINT'));
};

startServer();
