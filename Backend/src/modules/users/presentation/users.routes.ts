import { Router, type RequestHandler } from 'express';
import type { UsersController } from './users.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  listUsersQuerySchema,
  setMyRoleBodySchema,
  setUserRoleBodySchema,
  userIdParamsSchema,
} from './users.validation.js';

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

  // NOTE: registered before '/:id/role' so 'me' never matches the id param
  // (uuid validation would reject it with a confusing 422 otherwise).
  router.patch(
    '/me/role',
    authenticateMiddleware,
    validate({ body: setMyRoleBodySchema }),
    controller.setMyRole,
  );

  router.patch(
    '/:id/role',
    authenticateMiddleware,
    requireAdminMiddleware,
    validate({ params: userIdParamsSchema, body: setUserRoleBodySchema }),
    controller.setUserRole,
  );

  return router;
};
