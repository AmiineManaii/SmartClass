import rateLimit, { type Options, type RateLimitRequestHandler } from 'express-rate-limit';
import type { Request, Response } from 'express';
import { ErrorCodes } from '../errors/index.js';
import { getEnv } from '../../config/env.js';

export interface RateLimiterCustomOptions {
  windowMs?: number;
  limit?: number;
  message?: string;
  keyGenerator?: Options['keyGenerator'];
  skip?: Options['skip'];
}

export const createRateLimiter = (options: RateLimiterCustomOptions = {}): RateLimitRequestHandler => {
  return rateLimit({
    windowMs: options.windowMs ?? 60000,
    limit: options.limit ?? 100,
    standardHeaders: 'draft-8',
    legacyHeaders: false,
    keyGenerator: options.keyGenerator,
    skip: options.skip,
    handler: (req: Request, res: Response) => {
      const requestId =
        res.locals.requestId ||
        (typeof req.headers['x-request-id'] === 'string'
          ? req.headers['x-request-id']
          : 'unknown');

      res.status(429).json({
        error: {
          code: ErrorCodes.RATE_LIMITED,
          message: options.message ?? 'Too many requests, please try again later',
          details: [],
          requestId,
        },
      });
    },
  });
};

export const createGlobalRateLimiter = (): RateLimitRequestHandler => {
  const env = getEnv();
  return createRateLimiter({
    windowMs: env.RATE_LIMIT_WINDOW_MS,
    limit: env.RATE_LIMIT_MAX,
    message: 'Too many requests on API, please try again later',
  });
};
