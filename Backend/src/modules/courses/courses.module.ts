import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { CourseRepositoryPort } from './domain/course-repository.port.js';
import type { CourseSectionRepositoryPort } from './domain/course-section-repository.port.js';
import type { CourseStudyRepositoryPort } from './domain/course-study-repository.port.js';
import type { CoursePassageRetrievalPort } from './domain/course-passage-retrieval.port.js';
import { PrismaCourseRepositoryAdapter } from './infrastructure/prisma-course-repository.adapter.js';
import { PrismaCourseSectionRepositoryAdapter } from './infrastructure/prisma-course-section-repository.adapter.js';
import { PrismaCourseStudyRepositoryAdapter } from './infrastructure/prisma-course-study-repository.adapter.js';
import { PrismaCoursePassageRetrievalAdapter } from './infrastructure/prisma-course-passage-retrieval.adapter.js';
import {
  SmartModelRouterAdapter,
  type SmartModelRouterPort,
} from '../ai-assistant/index.js';
import { SaveCourseUseCase } from './application/save-course.use-case.js';
import { UpdateCourseUseCase } from './application/update-course.use-case.js';
import { ListMyCoursesUseCase } from './application/list-my-courses.use-case.js';
import { ListPublishedCoursesUseCase } from './application/list-published-courses.use-case.js';
import { GetCourseUseCase } from './application/get-course.use-case.js';
import { PublishCourseUseCase } from './application/publish-course.use-case.js';
import { UnpublishCourseUseCase } from './application/unpublish-course.use-case.js';
import { DeleteCourseUseCase } from './application/delete-course.use-case.js';
import {
  DeleteCourseStudyArtifactUseCase,
  GetCourseStudyWorkspaceUseCase,
} from './application/course-study.use-cases.js';
import { GenerateCourseStudyArtifactUseCase } from './application/generate-course-study-artifact.use-case.js';
import { AskCourseTutorUseCase } from './application/ask-course-tutor.use-case.js';
import { CoursesController } from './presentation/courses.controller.js';
import { createCoursesRouter } from './presentation/courses.routes.js';

import type { GroupRepositoryPort } from '../groups/domain/group-repository.port.js';
import type { KnowledgeIndexerPort, KnowledgeRetrievalPort } from '../knowledge/index.js';
import { KnowledgeCourseRetrievalBridge } from '../knowledge/index.js';

export interface CoursesModuleOptions {
  courseRepository?: CourseRepositoryPort;
  sectionRepository?: CourseSectionRepositoryPort;
  groupRepository?: GroupRepositoryPort;
  studyRepository?: CourseStudyRepositoryPort;
  passageRetrieval?: CoursePassageRetrievalPort;
  knowledgeIndexer?: KnowledgeIndexerPort;
  knowledgeRetrieval?: KnowledgeRetrievalPort;
  modelRouter?: SmartModelRouterPort;
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
  const sectionRepository =
    options.sectionRepository ?? new PrismaCourseSectionRepositoryAdapter();
  const groupRepository = options.groupRepository;

  const saveCourseUseCase = new SaveCourseUseCase(
    courseRepository,
    groupRepository,
    options.knowledgeIndexer,
  );
  const updateCourseUseCase = new UpdateCourseUseCase(
    courseRepository,
    groupRepository,
    options.knowledgeIndexer,
  );
  const listMyCoursesUseCase = new ListMyCoursesUseCase(courseRepository);
  const listPublishedCoursesUseCase = new ListPublishedCoursesUseCase(courseRepository, groupRepository);
  const getCourseUseCase = new GetCourseUseCase(courseRepository, groupRepository);
  const publishCourseUseCase = new PublishCourseUseCase(
    courseRepository,
    sectionRepository,
    options.knowledgeIndexer,
  );
  const unpublishCourseUseCase = new UnpublishCourseUseCase(
    courseRepository,
    options.knowledgeIndexer,
  );
  const deleteCourseUseCase = new DeleteCourseUseCase(courseRepository, options.knowledgeIndexer);

  // Student study slice: summaries, flashcards and the course-scoped tutor.
  const studyRepository = options.studyRepository ?? new PrismaCourseStudyRepositoryAdapter();
  const legacyPassageRetrieval = new PrismaCoursePassageRetrievalAdapter();
  const passageRetrieval =
    options.passageRetrieval ??
    (options.knowledgeRetrieval
      ? new KnowledgeCourseRetrievalBridge(options.knowledgeRetrieval, legacyPassageRetrieval)
      : legacyPassageRetrieval);
  const modelRouter = options.modelRouter ?? new SmartModelRouterAdapter();
  const getCourseStudyUseCase = new GetCourseStudyWorkspaceUseCase(
    courseRepository,
    groupRepository,
    studyRepository,
  );
  const generateCourseStudyArtifactUseCase = new GenerateCourseStudyArtifactUseCase(
    courseRepository,
    groupRepository,
    studyRepository,
    modelRouter,
  );
  const deleteCourseStudyArtifactUseCase = new DeleteCourseStudyArtifactUseCase(
    courseRepository,
    groupRepository,
    studyRepository,
  );
  const askCourseTutorUseCase = new AskCourseTutorUseCase(
    courseRepository,
    groupRepository,
    studyRepository,
    passageRetrieval,
    modelRouter,
  );

  const controller = new CoursesController(
    saveCourseUseCase,
    updateCourseUseCase,
    listMyCoursesUseCase,
    listPublishedCoursesUseCase,
    getCourseUseCase,
    publishCourseUseCase,
    unpublishCourseUseCase,
    deleteCourseUseCase,
    getCourseStudyUseCase,
    generateCourseStudyArtifactUseCase,
    deleteCourseStudyArtifactUseCase,
    askCourseTutorUseCase,
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
