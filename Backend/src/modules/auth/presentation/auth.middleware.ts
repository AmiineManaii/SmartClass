import type { Request, Response, NextFunction, RequestHandler } from 'express';
import type { TokenServicePort } from '../domain/token-service.port.js';
import type { Role, TeacherApprovalStatus, UserStatus } from '../domain/user.entity.js';
import { UnauthorizedError, ForbiddenError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';

export interface AuthenticatedUser {
  id: string;
  email: string;
  role: Role | null;
  status: UserStatus;
  teacherApprovalStatus?: TeacherApprovalStatus | null;
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
      let token: string | undefined;
      const authHeader = req.headers.authorization;

      if (authHeader) {
        const parts = authHeader.split(' ');
        if (parts.length === 2 && parts[0]?.toLowerCase() === 'bearer' && parts[1]) {
          token = parts[1];
        } else {
          throw new UnauthorizedError(
            'Malformed Authorization header. Format: Bearer <token>',
            ErrorCodes.AUTH_TOKEN_INVALID,
          );
        }
      }

      // Fallback 1: Query parameter (e.g. for SSE streams / EventSource where headers cannot be set)
      if (!token && req.query) {
        const queryToken = req.query.token ?? req.query.accessToken;
        if (typeof queryToken === 'string' && queryToken.trim().length > 0) {
          token = queryToken.trim();
        }
      }

      // Fallback 2: Cookie (for browser sessions with httpOnly cookie)
      if (!token && req.headers.cookie) {
        const match = req.headers.cookie.match(/(?:^|;\s*)smartclass_access_token=([^;]+)/);
        if (match && match[1]) {
          token = decodeURIComponent(match[1].trim());
        }
      }

      if (!token) {
        throw new UnauthorizedError(
          'Missing Authorization header. Expected Bearer <token>.',
          ErrorCodes.AUTH_TOKEN_INVALID,
        );
      }

      const payload = await tokenService.verifyAccessToken(token);

      if (payload.status === 'SUSPENDED') {
        throw new ForbiddenError(
          'Your account has been suspended.',
          ErrorCodes.AUTH_USER_SUSPENDED,
        );
      }

      req.user = {
        id: payload.sub,
        email: payload.email,
        role: payload.role,
        status: payload.status,
        teacherApprovalStatus: payload.teacherApprovalStatus ?? null,
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

export const createRequireApprovedTeacherMiddleware = (
  allowedRoles: Role[] = ['TEACHER', 'ADMIN'],
): RequestHandler => {
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
    if (req.user.role === 'TEACHER') {
      if (req.user.teacherApprovalStatus === 'PENDING') {
        throw new ForbiddenError(
          'Your teacher account is pending administrative approval.',
          ErrorCodes.FORBIDDEN,
        );
      }
      if (req.user.teacherApprovalStatus === 'REJECTED') {
        throw new ForbiddenError(
          'Your teacher account application has been rejected.',
          ErrorCodes.FORBIDDEN,
        );
      }
    }
    next();
  };
};
