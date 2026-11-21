import { Router, type RequestHandler } from 'express';
import type { CoursesController } from './courses.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import { createRateLimiter } from '../../../shared/http/rate-limiter.js';
import {
  askCourseTutorBodySchema,
  courseIdParamsSchema,
  courseStudyArtifactParamsSchema,
  generateCourseStudyBodySchema,
  saveCourseBodySchema,
  updateCourseBodySchema,
} from './courses.validation.js';

/** LLM-backed endpoints: cap per-user generation to protect the local GPU. */
const studyGenerateRateLimiter = createRateLimiter({
  windowMs: 60000,
  limit: 10,
  message: 'Too many AI study requests, please try again later',
});

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

  // Student study workspace: everything the reader screen needs in one call.
  router.get(
    '/:id/study',
    authenticateMiddleware,
    validate({ params: courseIdParamsSchema }),
    controller.getCourseStudy,
  );

  router.post(
    '/:id/study/artifacts',
    authenticateMiddleware,
    studyGenerateRateLimiter,
    validate({ params: courseIdParamsSchema, body: generateCourseStudyBodySchema }),
    controller.generateCourseStudyArtifact,
  );

  router.delete(
    '/:id/study/artifacts/:artifactId',
    authenticateMiddleware,
    validate({ params: courseStudyArtifactParamsSchema }),
    controller.deleteCourseStudyArtifact,
  );

  /** Course-scoped tutor: off-course questions are refused server-side. */
  router.post(
    '/:id/tutor/ask',
    authenticateMiddleware,
    studyGenerateRateLimiter,
    validate({ params: courseIdParamsSchema, body: askCourseTutorBodySchema }),
    controller.askCourseTutor,
  );

  router.get(
    '/:id',
    authenticateMiddleware,
    validate({ params: courseIdParamsSchema }),
    controller.getCourse,
  );

  router.patch(
    '/:id',
    authenticateMiddleware,
    requireTeacherMiddleware,
    validate({ params: courseIdParamsSchema, body: updateCourseBodySchema }),
    controller.updateCourse,
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
