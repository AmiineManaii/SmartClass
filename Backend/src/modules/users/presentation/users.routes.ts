import { Router, type RequestHandler } from 'express';
import type { UsersController } from './users.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import { listUsersQuerySchema } from './users.validation.js';

export interface UsersRouterOptions {
  controller: UsersController;
  authenticateMiddleware: RequestHandler;
  requireAdminMiddleware: RequestHandler;
}

export const createUsersRouter = (options: UsersRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireAdminMiddleware } = options;

  router.get(
    '/',
    authenticateMiddleware,
    requireAdminMiddleware,
    validate({ query: listUsersQuerySchema }),
    controller.listUsers,
  );

  return router;
};
