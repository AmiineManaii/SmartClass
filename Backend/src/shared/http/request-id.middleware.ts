import { randomUUID } from 'node:crypto';
import type { Request, Response, NextFunction } from 'express';

// Augment Express Request with 'id' property
declare module 'express-serve-static-core' {
  interface Request {
    id?: string;
  }
}

export const requestIdMiddleware = (
  req: Request,
  res: Response,
  next: NextFunction,
): void => {
  const incomingId = req.headers['x-request-id'];
  const requestId =
    typeof incomingId === 'string' && incomingId.trim().length > 0
      ? incomingId.trim()
      : randomUUID();

  req.id = requestId;
  res.locals.requestId = requestId;
  res.setHeader('X-Request-Id', requestId);

  next();
};
