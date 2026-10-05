import { describe, it, expect, vi } from 'vitest';
import type { Request, Response } from 'express';
import {
  AppError,
  NotFoundError,
  ValidationError,
  ServiceUnavailableError,
  BadRequestError,
  ErrorCodes,
} from '../../src/shared/errors/index.js';

describe('AppError Hierarchy', () => {
  it('AppError carries all properties', () => {
    const err = new AppError('test', 500, ErrorCodes.INTERNAL_ERROR, [{ foo: 'bar' }], false);
    expect(err.statusCode).toBe(500);
    expect(err.code).toBe('INTERNAL_ERROR');
    expect(err.details).toEqual([{ foo: 'bar' }]);
    expect(err.isOperational).toBe(false);
    expect(err.message).toBe('test');
    expect(err).toBeInstanceOf(Error);
  });

  it('NotFoundError defaults', () => {
    const err = new NotFoundError();
    expect(err.statusCode).toBe(404);
    expect(err.code).toBe('NOT_FOUND');
    expect(err.isOperational).toBe(true);
  });

  it('ValidationError with details', () => {
    const details = [{ path: 'email', message: 'Required' }];
    const err = new ValidationError('Validation failed', details);
    expect(err.statusCode).toBe(422);
    expect(err.code).toBe('VALIDATION_ERROR');
    expect(err.details).toEqual(details);
  });

  it('BadRequestError defaults', () => {
    const err = new BadRequestError();
    expect(err.statusCode).toBe(400);
    expect(err.code).toBe('BAD_REQUEST');
  });

  it('ServiceUnavailableError defaults', () => {
    const err = new ServiceUnavailableError();
    expect(err.statusCode).toBe(503);
    expect(err.code).toBe('SERVICE_UNAVAILABLE');
  });
});

describe('Error Handler Middleware', () => {
  // Lazy import to avoid env parsing before setting env vars
  const createMockReqRes = () => {
    const req = {
      headers: { 'x-request-id': 'test-req-id' },
    } as unknown as Request;
    const res = {
      locals: { requestId: 'test-req-id' },
      status: vi.fn().mockReturnThis(),
      json: vi.fn().mockReturnThis(),
    } as unknown as Response;
    const next = vi.fn();
    return { req, res, next };
  };

  it('handles AppError with correct envelope', async () => {
    // Dynamically import to avoid module-level side effects
    const { errorHandler } = await import('../../src/shared/http/error-handler.middleware.js');
    const { req, res, next } = createMockReqRes();
    const err = new NotFoundError('User not found');

    errorHandler(err, req, res, next);

    expect(res.status).toHaveBeenCalledWith(404);
    expect(res.json).toHaveBeenCalledWith({
      error: {
        code: 'NOT_FOUND',
        message: 'User not found',
        details: [],
        requestId: 'test-req-id',
      },
    });
  });

  it('handles unknown errors as INTERNAL_ERROR', async () => {
    const { errorHandler } = await import('../../src/shared/http/error-handler.middleware.js');
    const { req, res, next } = createMockReqRes();
    const err = new Error('Something unexpected');

    errorHandler(err, req, res, next);

    expect(res.status).toHaveBeenCalledWith(500);
    expect(res.json).toHaveBeenCalledWith(
      expect.objectContaining({
        error: expect.objectContaining({
          code: 'INTERNAL_ERROR',
          message: 'Internal server error',
        }),
      }),
    );
  });
});
