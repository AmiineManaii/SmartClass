import { Router, type RequestHandler } from 'express';
import type { CoursesController } from './courses.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  courseIdParamsSchema,
  saveCourseBodySchema,
} from './courses.validation.js';

export interface CoursesRouterOptions {
  controller: CoursesController;
  authenticateMiddleware: RequestHandler;
  requireTeacherMiddleware: RequestHandler;
}

export const createCoursesRouter = (options: CoursesRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireTeacherMiddleware } = options;

  // NOTE: static segments before '/:id' so 'mine'/'published' never match
  // the uuid param (same rationale as '/mine' in the groups module).
  router.post(
    '/',
    authenticateMiddleware,
    requireTeacherMiddleware,
    validate({ body: saveCourseBodySchema }),
    controller.saveCourse,
  );

  router.get('/mine', authenticateMiddleware, requireTeacherMiddleware, controller.listMyCourses);

  router.get('/published', authenticateMiddleware, controller.listPublishedCourses);

  router.get(
    '/:id',
    authenticateMiddleware,
    validate({ params: courseIdParamsSchema }),
    controller.getCourse,
  );

  router.patch(
    '/:id/publish',
    authenticateMiddleware,
    requireTeacherMiddleware,
    validate({ params: courseIdParamsSchema }),
    controller.publishCourse,
  );

  router.patch(
    '/:id/unpublish',
    authenticateMiddleware,
    requireTeacherMiddleware,
    validate({ params: courseIdParamsSchema }),
    controller.unpublishCourse,
  );

  router.delete(
    '/:id',
    authenticateMiddleware,
    requireTeacherMiddleware,
    validate({ params: courseIdParamsSchema }),
    controller.deleteCourse,
  );

  return router;
};
