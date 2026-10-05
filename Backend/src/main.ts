import type { Server } from 'node:http';
import { getEnv } from './config/env.js';
import { logger } from './shared/infrastructure/logger.js';
import { getPrismaClient, disconnectPrisma } from './shared/infrastructure/prisma.js';
import { printServerBanner } from './shared/infrastructure/banner.js';
import { createApp } from './app.js';

const startServer = (): void => {
  const env = getEnv();
  const app = createApp();

  const server: Server = app.listen(env.PORT, async () => {
    logger.info(
      {
        port: env.PORT,
        nodeEnv: env.NODE_ENV,
        nodeVersion: process.version,
      },
      `🚀 SmartClass API server listening on port ${env.PORT}`,
    );

    // Verify database connectivity
    let dbStatus: 'CONNECTED' | 'FAILED' = 'FAILED';
    let dbLatencyMs: number | undefined;

    try {
      const prisma = getPrismaClient();
      const start = performance.now();
      await prisma.$queryRaw`SELECT 1`;
      dbLatencyMs = Math.round(performance.now() - start);
      dbStatus = 'CONNECTED';
      logger.info({ latencyMs: dbLatencyMs }, 'Database connection established successfully');
    } catch (err) {
      logger.error({ err }, 'Failed to establish database connection during startup');
    }

    // Print Spring Boot style ASCII banner when server and DB are live
    printServerBanner({
      port: env.PORT,
      nodeEnv: env.NODE_ENV,
      dbStatus,
      dbLatencyMs,
    });
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
