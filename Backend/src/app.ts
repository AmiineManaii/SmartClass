import express, { type Express, type RequestHandler } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { pinoHttp } from 'pino-http';
import { getEnv } from './config/env.js';
import { logger } from './shared/infrastructure/logger.js';
import { requestIdMiddleware } from './shared/http/request-id.middleware.js';
import { notFoundHandler } from './shared/http/not-found.middleware.js';
import { errorHandler } from './shared/http/error-handler.middleware.js';
import { createGlobalRateLimiter, createRateLimiter, type RateLimiterCustomOptions } from './shared/http/rate-limiter.js';
import { createHealthModule, type HealthModuleOptions } from './modules/health/index.js';
import { createApiRouter } from './routes.js';

export interface CreateAppOptions {
  healthModuleOptions?: HealthModuleOptions;
  rateLimiterOptions?: RateLimiterCustomOptions;
  skipRateLimit?: boolean;
  skipLogging?: boolean;
}

export const createApp = (options: CreateAppOptions = {}): Express => {
  const env = getEnv();
  const app = express();

  // 1. Basic security & proxy settings
  app.disable('x-powered-by');
  if (env.TRUST_PROXY && env.TRUST_PROXY !== '0') {
    app.set('trust proxy', isNaN(Number(env.TRUST_PROXY)) ? env.TRUST_PROXY : Number(env.TRUST_PROXY));
  }

  // 2. Request ID tracking
  app.use(requestIdMiddleware);

  // 3. Structured HTTP logging
  if (!options.skipLogging && env.NODE_ENV !== 'test') {
    app.use(
      pinoHttp({
        logger,
        genReqId: (req) => req.id || 'unknown',
        customLogLevel: (res, err) => {
          const statusCode = res.statusCode ?? 200;
          if (statusCode >= 500 || err) return 'error';
          if (statusCode >= 400) return 'warn';
          return 'info';
        },
      }) as unknown as RequestHandler,
    );
  }

  // 4. Security headers
  app.use(helmet() as unknown as RequestHandler);

  // 5. CORS whitelist
  app.use(
    cors({
      origin: (origin, callback) => {
        // Allow requests with no origin (like mobile apps, curl, server-to-server)
        if (!origin || env.CORS_ORIGINS.includes(origin)) {
          callback(null, true);
        } else {
          callback(new Error(`Origin '${origin}' not allowed by CORS`));
        }
      },
      credentials: true,
    }) as unknown as RequestHandler,
  );

  // 6. Body parsers (1mb limit)
  app.use(express.json({ limit: '1mb' }) as unknown as RequestHandler);
  app.use(express.urlencoded({ extended: true, limit: '1mb' }) as unknown as RequestHandler);

  // 7. Health routes (unversioned, exempt from rate limits)
  const healthModule = createHealthModule(options.healthModuleOptions);
  app.use('/health', healthModule.router);

  // 8. API v1 Router with Rate Limiting
  const rateLimiter = options.skipRateLimit
    ? undefined
    : options.rateLimiterOptions
      ? createRateLimiter(options.rateLimiterOptions)
      : createGlobalRateLimiter();

  const apiRouter = createApiRouter();
  if (rateLimiter) {
    app.use('/api/v1', rateLimiter as unknown as RequestHandler, apiRouter);
  } else {
    app.use('/api/v1', apiRouter);
  }

  // 9. 404 Route Not Found handler
  app.use(notFoundHandler);

  // 10. Central Error handler
  app.use(errorHandler);

  return app;
};
