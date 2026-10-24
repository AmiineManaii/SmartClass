import express, { type Express, type RequestHandler } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { pinoHttp } from 'pino-http';
import { getEnv } from './config/env.js';
import { logger } from './shared/infrastructure/logger.js';
import { requestIdMiddleware } from './shared/http/request-id.middleware.js';
import { notFoundHandler } from './shared/http/not-found.middleware.js';
import { errorHandler } from './shared/http/error-handler.middleware.js';
import {
  createGlobalRateLimiter,
  createRateLimiter,
  type RateLimiterCustomOptions,
} from './shared/http/rate-limiter.js';
import type { AuthModuleOptions } from './modules/auth/index.js';
import { createHealthModule, type HealthModuleOptions } from './modules/health/index.js';
import type { UsersModuleOptions } from './modules/users/index.js';
import type { AdminModuleOptions } from './modules/admin/index.js';
import type { AiModuleOptions } from './modules/ai-assistant/index.js';
import type { GroupsModuleOptions } from './modules/groups/index.js';
import type { ExamsModuleOptions } from './modules/exams/index.js';
import type { VideoconferenceModuleOptions } from './modules/videoconference/index.js';
import { createApiRouter } from './routes.js';

export interface CreateAppOptions {
  healthModuleOptions?: HealthModuleOptions;
  authModuleOptions?: AuthModuleOptions;
  usersModuleOptions?: UsersModuleOptions;
  adminModuleOptions?: AdminModuleOptions;
  aiModuleOptions?: AiModuleOptions;
  groupsModuleOptions?: GroupsModuleOptions;
  examsModuleOptions?: ExamsModuleOptions;
  videoconferenceModuleOptions?: VideoconferenceModuleOptions;
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
    app.set(
      'trust proxy',
      isNaN(Number(env.TRUST_PROXY)) ? env.TRUST_PROXY : Number(env.TRUST_PROXY),
    );
  }

  // 2. Request ID tracking
  app.use(requestIdMiddleware);

  // 3. Structured HTTP logging
  if (!options.skipLogging && env.NODE_ENV !== 'test') {
    app.use(
      pinoHttp({
        logger,
        genReqId: (req) => req.id || 'unknown',
        autoLogging: {
          ignore: (req) => req.url === '/health/live',
        },
        customLogLevel: (req, res, err) => {
          const statusCode = res?.statusCode ?? 200;
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
        if (!origin) {
          callback(null, true);
          return;
        }

        // Whitelisted origins or wildcard
        if (env.CORS_ORIGINS.includes('*') || env.CORS_ORIGINS.includes(origin)) {
          callback(null, true);
          return;
        }

        // In development: allow any localhost / 127.0.0.1 port (e.g. Flutter Web dynamic ports)
        if (env.NODE_ENV === 'development') {
          const isLocalhost = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/.test(origin);
          if (isLocalhost) {
            callback(null, true);
            return;
          }
        }

        callback(new Error(`Origin '${origin}' not allowed by CORS`));
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

  // 7b. Direct /search-images contract (Ollama Lucy + SearxNG)
  app.post('/search-images', async (req, res, next) => {
    try {
      const { keywords, section, count = 5 } = req.body || {};
      if (!keywords || typeof keywords !== 'string' || !keywords.trim()) {
        res.status(400).json({ error: 'Le champ "keywords" est requis et doit être une chaîne non vide.' });
        return;
      }
      if (typeof section !== 'string') {
        res.status(400).json({ error: 'Le champ "section" doit être une chaîne de caractères.' });
        return;
      }
      const parsedCount = count !== undefined ? parseInt(String(count), 10) : 50;
      const effectiveCount = isNaN(parsedCount) || parsedCount < 1 ? 50 : Math.min(parsedCount, 50);

      // 1. Reformulation via Ollama (Lucy)
      const fallbackQuery = `${section} ${keywords}`.replace(/\s+/g, ' ').trim().slice(0, 200);
      let queryUsed = fallbackQuery;

      const env = getEnv();
      const ollamaUrl = env.AI_BASE_URL.replace(/\/+$/, '');
      const model = env.OLLAMA_REFORMULATE_MODEL || 'sam860/lucy:1.7b';

      try {
        const ollamaRes = await fetch(`${ollamaUrl}/api/chat`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model,
            messages: [
              {
                role: 'system',
                content: `Tu es un assistant qui transforme une description de section de cours en requête de
recherche d'images efficace.

Règles :
- Réponds UNIQUEMENT par la requête finale, en mots-clés.
- Pas de phrase, pas de ponctuation finale, pas de guillemets, pas d'explication.
- 4 à 8 mots-clés maximum.
- Traduis en anglais si les termes techniques anglais sont plus courants.
- Ajoute le contexte technique pertinent (ex: "database", "diagram", "schema", "tutorial").
- Exemple : "modélisation conceptuelle base de données" → "conceptual database model ER diagram schema"

Ne réponds jamais autre chose que la requête.`,
              },
              { role: 'user', content: `Section: ${section}\nDescription: ${keywords}` },
            ],
            stream: false,
            options: { temperature: 0.2, num_predict: 60 },
          }),
          signal: AbortSignal.timeout(10_000),
        });

        if (ollamaRes.ok) {
          const data = (await ollamaRes.json()) as { message?: { content?: string } };
          const cleaned = (data.message?.content || '')
            .replace(/["'«»`]/g, ' ')
            .replace(/[\r\n\t]+/g, ' ')
            .replace(/[.;:!?]+$/g, '')
            .replace(/\s+/g, ' ')
            .trim()
            .slice(0, 200);
          if (cleaned) queryUsed = cleaned;
        }
      } catch (ollamaErr) {
        logger.warn({ error: (ollamaErr as Error).message }, '[/search-images] Ollama Lucy failed, using fallback');
      }

      // 2. Recherche SearxNG
      let urls: string[] = [];
      try {
        const searxUrl = `${env.SEARXNG_URL.replace(/\/+$/, '')}/search?q=${encodeURIComponent(queryUsed)}&categories=images&format=json`;
        const searxRes = await fetch(searxUrl, {
          headers: { 'Accept': 'application/json', 'User-Agent': 'SmartClass/1.0' },
          signal: AbortSignal.timeout(5_000),
        });

        if (searxRes.ok) {
          const searxData = (await searxRes.json()) as {
            results?: Array<{ img_src?: string; url?: string; thumbnail_src?: string }>;
          };
          const seen = new Set<string>();

          for (const item of searxData.results ?? []) {
            const src = item.img_src || item.url || item.thumbnail_src;
            if (src && src.startsWith('http') && !seen.has(src)) {
              seen.add(src);
              urls.push(src);
              if (urls.length >= effectiveCount) break;
            }
          }
        } else {
          logger.warn({ status: searxRes.status }, '[/search-images] SearxNG non-200');
        }
      } catch (searxErr) {
        logger.warn({ error: (searxErr as Error).message }, '[/search-images] SearxNG request failed');
      }

      res.status(200).json({ urls, query_used: queryUsed });
    } catch (err) {
      next(err);
    }
  });

  // 8. API v1 Router with Rate Limiting
  const rateLimiter = options.skipRateLimit
    ? undefined
    : options.rateLimiterOptions
      ? createRateLimiter(options.rateLimiterOptions)
      : createGlobalRateLimiter();

  const apiRouter = createApiRouter({
    authModuleOptions: options.authModuleOptions,
    usersModuleOptions: options.usersModuleOptions,
    adminModuleOptions: options.adminModuleOptions,
    aiModuleOptions: options.aiModuleOptions,
    groupsModuleOptions: options.groupsModuleOptions,
    examsModuleOptions: options.examsModuleOptions,
    videoconferenceModuleOptions: options.videoconferenceModuleOptions,
  });
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
