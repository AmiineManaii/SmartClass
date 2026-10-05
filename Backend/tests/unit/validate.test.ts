import { describe, it, expect, vi } from 'vitest';
import type { Request, Response, NextFunction } from 'express';
import { z } from 'zod';

describe('Validate Middleware', () => {
  const createMockReqRes = (overrides: Partial<Request> = {}) => {
    const req = {
      body: {},
      query: {},
      params: {},
      ...overrides,
    } as unknown as Request;
    const res = {} as Response;
    const next = vi.fn() as unknown as NextFunction;
    return { req, res, next };
  };

  it('passes when body matches schema', async () => {
    const { validate } = await import('../../src/shared/http/validate.middleware.js');
    const schema = z.object({ name: z.string() }).strict();
    const { req, res, next } = createMockReqRes({ body: { name: 'Alice' } });

    validate({ body: schema })(req, res, next);

    expect(next).toHaveBeenCalledWith();
    expect(req.body).toEqual({ name: 'Alice' });
  });

  it('calls next with ValidationError when body fails', async () => {
    const { validate } = await import('../../src/shared/http/validate.middleware.js');
    const schema = z.object({ name: z.string() }).strict();
    const { req, res, next } = createMockReqRes({ body: { name: 123 } });

    validate({ body: schema })(req, res, next);

    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'VALIDATION_ERROR',
        statusCode: 422,
      }),
    );
  });

  it('rejects unknown fields with strict schema', async () => {
    const { validate } = await import('../../src/shared/http/validate.middleware.js');
    const schema = z.object({ name: z.string() }).strict();
    const { req, res, next } = createMockReqRes({
      body: { name: 'Alice', admin: true },
    });

    validate({ body: schema })(req, res, next);

    expect(next).toHaveBeenCalledWith(
      expect.objectContaining({
        code: 'VALIDATION_ERROR',
      }),
    );
  });

  it('validates query parameters', async () => {
    const { validate } = await import('../../src/shared/http/validate.middleware.js');
    const schema = z.object({ page: z.coerce.number().int() }).strict();
    const { req, res, next } = createMockReqRes();
    req.query = { page: '2' } as unknown as Request['query'];

    validate({ query: schema })(req, res, next);

    expect(next).toHaveBeenCalledWith();
  });
});
