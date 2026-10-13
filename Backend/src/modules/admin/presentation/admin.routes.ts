import { Router, type RequestHandler } from 'express';
import type { AdminController } from './admin.controller.js';

export interface AdminRouterOptions {
  controller: AdminController;
  authenticateMiddleware: RequestHandler;
  requireAdminMiddleware: RequestHandler;
}

export const createAdminRouter = (options: AdminRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireAdminMiddleware } = options;

  router.use(authenticateMiddleware, requireAdminMiddleware);

  router.get('/overview', controller.getOverview);

  return router;
};
