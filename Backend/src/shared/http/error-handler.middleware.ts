import type { Request, Response, NextFunction, ErrorRequestHandler } from 'express';
import { AppError, ErrorCodes, type ErrorCode } from '../errors/index.js';
import { logger } from '../infrastructure/logger.js';

interface ErrorEnvelope {
  error: {
    code: ErrorCode;
    message: string;
    details: unknown[];
    requestId: string;
  };
}

export const errorHandler: ErrorRequestHandler = (
  err: Error,
  req: Request,
  res: Response,
  _next: NextFunction,
): void => {
  const requestId =
    res.locals.requestId ||
    (typeof req.headers['x-request-id'] === 'string'
      ? req.headers['x-request-id']
      : 'unknown');

  // Handle AppError and its subclasses
  if (err instanceof AppError) {
    if (err.statusCode >= 500) {
      logger.error({ err, requestId }, `Operational server error: ${err.message}`);
    } else {
      logger.warn({ err, requestId }, `Client error [${err.code}]: ${err.message}`);
    }

    const envelope: ErrorEnvelope = {
      error: {
        code: err.code,
        message: err.message,
        details: err.details,
        requestId,
      },
    };

    res.status(err.statusCode).json(envelope);
    return;
  }

  // Handle JSON parse errors from body-parser
  if ('type' in err && (err as { type: string }).type === 'entity.parse.failed') {
    logger.warn({ err, requestId }, 'Malformed JSON body in request');
    const envelope: ErrorEnvelope = {
      error: {
        code: ErrorCodes.BAD_REQUEST,
        message: 'Malformed JSON body',
        details: [],
        requestId,
      },
    };
    res.status(400).json(envelope);
    return;
  }

  // Unhandled / Unexpected internal errors
  logger.error({ err, requestId }, `Unhandled internal error: ${err.message}`);

  const envelope: ErrorEnvelope = {
    error: {
      code: ErrorCodes.INTERNAL_ERROR,
      message: 'Internal server error',
      details: [],
      requestId,
    },
  };

  res.status(500).json(envelope);
};
