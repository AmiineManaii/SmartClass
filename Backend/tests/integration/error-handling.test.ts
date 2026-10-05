import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { createApp } from '../../src/app.js';

describe('Integration: Error Handling Middleware', () => {
  const app = createApp({ skipLogging: true });

  it('returns 404 with structured error envelope for non-existent routes', async () => {
    const res = await request(app).get('/api/v1/non-existent-resource');

    expect(res.status).toBe(404);
    expect(res.body).toEqual({
      error: {
        code: 'NOT_FOUND',
        message: 'Route GET /api/v1/non-existent-resource not found',
        details: [],
        requestId: expect.any(String),
      },
    });
    expect(res.headers['x-request-id']).toBe(res.body.error.requestId);
  });

  it('preserves incoming X-Request-Id header across error responses', async () => {
    const customId = 'client-provided-trace-id-12345';
    const res = await request(app)
      .get('/api/v1/not-found')
      .set('X-Request-Id', customId);

    expect(res.status).toBe(404);
    expect(res.headers['x-request-id']).toBe(customId);
    expect(res.body.error.requestId).toBe(customId);
  });

  it('catches invalid JSON body and returns 400 BAD_REQUEST', async () => {
    const res = await request(app)
      .post('/api/v1/anything')
      .set('Content-Type', 'application/json')
      .send('{"bad-json-syntax": ');

    expect(res.status).toBe(400);
    expect(res.body.error).toBeDefined();
    expect(res.body.error.code).toBe('BAD_REQUEST');
    expect(res.body.error.message).toBe('Malformed JSON body');
    expect(res.body.error.requestId).toBeDefined();
  });
});
