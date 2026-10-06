import type { Request, Response, NextFunction, RequestHandler } from 'express';
import type { TokenServicePort } from '../domain/token-service.port.js';
import type { Role, UserStatus } from '../domain/user.entity.js';
import { UnauthorizedError, ForbiddenError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface AuthenticatedUser {
  id: string;
  email: string;
  role: Role | null;
  status: UserStatus;
}

declare module 'express-serve-static-core' {
  interface Request {
    user?: AuthenticatedUser;
  }
}

export const createAuthenticateMiddleware = (
  tokenService: TokenServicePort,
): RequestHandler => {
  return async (req: Request, _res: Response, next: NextFunction): Promise<void> => {
    try {
      const authHeader = req.headers.authorization;

      if (!authHeader) {
        throw new UnauthorizedError(
          'Missing Authorization header. Expected Bearer <token>.',
          ErrorCodes.AUTH_TOKEN_INVALID,
        );
      }

      const parts = authHeader.split(' ');
      if (parts.length !== 2 || parts[0]?.toLowerCase() !== 'bearer' || !parts[1]) {
        throw new UnauthorizedError(
          'Malformed Authorization header. Format: Bearer <token>',
          ErrorCodes.AUTH_TOKEN_INVALID,
        );
      }

      const token = parts[1];
      const payload = await tokenService.verifyAccessToken(token);

      req.user = {
        id: payload.sub,
        email: payload.email,
        role: payload.role,
        status: payload.status,
      };

      next();
    } catch (err) {
      next(err);
    }
  };
};

export const createRequireRoleMiddleware = (allowedRoles: Role[]): RequestHandler => {
  return (req: Request, _res: Response, next: NextFunction): void => {
    if (!req.user) {
      throw new UnauthorizedError('Authentication required', ErrorCodes.AUTH_TOKEN_INVALID);
    }
    if (!req.user.role || !allowedRoles.includes(req.user.role)) {
      throw new ForbiddenError(
        `Access denied. Requires one of the following roles: [${allowedRoles.join(', ')}]`,
        ErrorCodes.FORBIDDEN,
      );
    }
    next();
  };
};
