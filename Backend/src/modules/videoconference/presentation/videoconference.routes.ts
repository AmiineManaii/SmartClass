import { Router, type RequestHandler } from 'express';
import type { VideoconferenceController } from './videoconference.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import { timetableQuerySchema } from './videoconference.validation.js';

export interface VideoconferenceRouterOptions {
  controller: VideoconferenceController;
  authenticateMiddleware: RequestHandler;
  requireAdminMiddleware: RequestHandler;
}

export const createVideoconferenceRouter = (options: VideoconferenceRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireAdminMiddleware } = options;

  router.get(
    '/timetable',
    authenticateMiddleware,
    requireAdminMiddleware,
    validate({ query: timetableQuerySchema }),
    controller.getTimetable,
  );

  return router;
};
