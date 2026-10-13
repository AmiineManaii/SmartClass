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
  const { controller, authenticateMiddleware } = options;

  // Class-scoped read: any authenticated user belonging to the class
  // (member, assigned teacher, referent) plus ADMIN. Membership is
  // enforced in the use-case, not by a role guard.
  router.get(
    '/timetable',
    authenticateMiddleware,
    validate({ query: timetableQuerySchema }),
    controller.getTimetable,
  );

  return router;
};
