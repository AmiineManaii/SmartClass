import type { Request, Response, NextFunction } from 'express';
import type { ZodSchema, ZodError } from 'zod';
import { ValidationError, type ErrorDetail } from '../errors/index.js';

interface ValidationSchemas {
  body?: ZodSchema;
  query?: ZodSchema;
  params?: ZodSchema;
}

const formatZodErrors = (error: ZodError): ErrorDetail[] => {
  return error.errors.map((err) => ({
    path: err.path.join('.'),
    message: err.message,
  }));
};

export const validate = (schemas: ValidationSchemas) => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const details: ErrorDetail[] = [];

    if (schemas.body) {
      const result = schemas.body.safeParse(req.body);
      if (!result.success) {
        details.push(...formatZodErrors(result.error));
      } else {
        req.body = result.data;
      }
    }

    if (schemas.query) {
      const result = schemas.query.safeParse(req.query);
      if (!result.success) {
        details.push(...formatZodErrors(result.error));
      } else {
        req.query = result.data as typeof req.query;
      }
    }

    if (schemas.params) {
      const result = schemas.params.safeParse(req.params);
      if (!result.success) {
        details.push(...formatZodErrors(result.error));
      } else {
        req.params = result.data as typeof req.params;
      }
    }

    if (details.length > 0) {
      next(new ValidationError('Validation failed', details));
      return;
    }

    next();
  };
};
