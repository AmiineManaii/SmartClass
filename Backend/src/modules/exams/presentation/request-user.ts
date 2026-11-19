import type { Request } from 'express';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';

export interface RequestUser {
  id: string;
  role: Role | null;
}

export const requireUser = (req: Request): RequestUser => {
  if (!req.user) {
    throw new UnauthorizedError('Authentication required');
  }
  return { id: req.user.id, role: req.user.role };
};
