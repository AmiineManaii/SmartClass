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

const setValidatedQuery = (req: Request, data: unknown): void => {
  try {
    req.query = data as typeof req.query;
  } catch {
    // Express 5 exposes req.query as getter-only: stash the coerced values
    // where controllers can read them (see validatedQuery).
    (req as unknown as { validatedQuery: unknown }).validatedQuery = data;
  }
};

/**
 * Returns the validated (and coerced) query object previously stored by
 * {@link validate}, falling back to the raw query when no query schema ran.
 */
export const validatedQuery = <T>(req: Request): T =>
  ((req as unknown as { validatedQuery?: unknown }).validatedQuery ?? req.query) as T;

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
        setValidatedQuery(req, result.data);
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
