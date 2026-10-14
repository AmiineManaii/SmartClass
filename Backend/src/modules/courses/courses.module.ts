import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { CourseRepositoryPort } from './domain/course-repository.port.js';
import { PrismaCourseRepositoryAdapter } from './infrastructure/prisma-course-repository.adapter.js';
import { SaveCourseUseCase } from './application/save-course.use-case.js';
import { UpdateCourseUseCase } from './application/update-course.use-case.js';
import { ListMyCoursesUseCase } from './application/list-my-courses.use-case.js';
import { ListPublishedCoursesUseCase } from './application/list-published-courses.use-case.js';
import { GetCourseUseCase } from './application/get-course.use-case.js';
import { PublishCourseUseCase } from './application/publish-course.use-case.js';
import { UnpublishCourseUseCase } from './application/unpublish-course.use-case.js';
import { DeleteCourseUseCase } from './application/delete-course.use-case.js';
import { CoursesController } from './presentation/courses.controller.js';
import { createCoursesRouter } from './presentation/courses.routes.js';

export interface CoursesModuleOptions {
  courseRepository?: CourseRepositoryPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireTeacherMiddleware?: RequestHandler;
}

export interface CoursesModule {
  router: Router;
  controller: CoursesController;
}

export const createCoursesModule = (options: CoursesModuleOptions = {}): CoursesModule => {
  const courseRepository = options.courseRepository ?? new PrismaCourseRepositoryAdapter();

  const saveCourseUseCase = new SaveCourseUseCase(courseRepository);
  const updateCourseUseCase = new UpdateCourseUseCase(courseRepository);
  const listMyCoursesUseCase = new ListMyCoursesUseCase(courseRepository);
  const listPublishedCoursesUseCase = new ListPublishedCoursesUseCase(courseRepository);
  const getCourseUseCase = new GetCourseUseCase(courseRepository);
  const publishCourseUseCase = new PublishCourseUseCase(courseRepository);
  const unpublishCourseUseCase = new UnpublishCourseUseCase(courseRepository);
  const deleteCourseUseCase = new DeleteCourseUseCase(courseRepository);

  const controller = new CoursesController(
    saveCourseUseCase,
    updateCourseUseCase,
    listMyCoursesUseCase,
    listPublishedCoursesUseCase,
    getCourseUseCase,
    publishCourseUseCase,
    unpublishCourseUseCase,
    deleteCourseUseCase,
  );

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('CoursesModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireTeacherMiddleware =
    options.requireTeacherMiddleware ??
    createRequireRoleMiddleware(['TEACHER', 'ADMIN'] as Role[]);

  const router = createCoursesRouter({
    controller,
    authenticateMiddleware,
    requireTeacherMiddleware,
  });

  return { router, controller };
};
