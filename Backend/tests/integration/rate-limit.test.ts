import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';
import { ErrorCodes } from '../../src/shared/errors/index.js';

describe('Integration: Rate Limiting', () => {
  it('enforces rate limit on /api/v1 and returns 429 when quota exceeded', async () => {
    // Configure app with low limit: 2 requests per window
    const app = createApp({
      skipLogging: true,
      rateLimiterOptions: {
        windowMs: 60 * 1000,
        limit: 2,
      },
    });

    const res1 = await request(app).get('/api/v1/ping');
    expect(res1.status).toBe(404); // Route doesn't exist, but consumed 1 token

    const res2 = await request(app).get('/api/v1/ping');
    expect(res2.status).toBe(404);

    const res3 = await request(app).get('/api/v1/ping');
    expect(res3.status).toBe(429);
    expect(res3.body).toEqual({
      error: {
        code: ErrorCodes.RATE_LIMITED,
        message: 'Too many requests, please try again later',
        details: [],
        requestId: expect.any(String),
      },
    });
    expect(res3.headers['retry-after']).toBeDefined();
  });

  it('/health endpoints are exempt from rate limiting', async () => {
    const app = createApp({
      skipLogging: true,
      rateLimiterOptions: {
        windowMs: 60 * 1000,
        limit: 1,
      },
    });

    // Make multiple health checks
    const res1 = await request(app).get('/health/live');
    const res2 = await request(app).get('/health/live');
    const res3 = await request(app).get('/health/live');

    expect(res1.status).toBe(200);
    expect(res2.status).toBe(200);
    expect(res3.status).toBe(200);
  });
});
