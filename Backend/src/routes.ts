import { Router } from 'express';
import { getEnv } from './config/env.js';
import { createAuthModule, type AuthModuleOptions, type Role } from './modules/auth/index.js';
import { createUsersModule, type UsersModuleOptions } from './modules/users/index.js';
import { createAdminModule, type AdminModuleOptions } from './modules/admin/index.js';
import {
  createAiModule,
  OllamaEmbeddingAdapter,
  PrismaSectionMemoryAdapter,
  SmartModelRouterAdapter,
  type AiModuleOptions,
  type SmartModelRouterPort,
} from './modules/ai-assistant/index.js';
import { createGroupsModule, type GroupsModuleOptions } from './modules/groups/index.js';
import { createCoursesModule, type CoursesModuleOptions } from './modules/courses/index.js';
import { createExamsModule, type ExamsModuleOptions } from './modules/exams/index.js';
import {
  createVideoconferenceModule,
  type VideoconferenceModuleOptions,
} from './modules/videoconference/index.js';
import {
  createKnowledgeModule,
  KnowledgeSectionMemoryBridge,
  type KnowledgeModuleOptions,
} from './modules/knowledge/index.js';

export interface ApiRouterOptions {
  authModuleOptions?: AuthModuleOptions;
  usersModuleOptions?: UsersModuleOptions;
  adminModuleOptions?: AdminModuleOptions;
  aiModuleOptions?: AiModuleOptions;
  groupsModuleOptions?: GroupsModuleOptions;
  coursesModuleOptions?: CoursesModuleOptions;
  examsModuleOptions?: ExamsModuleOptions;
  videoconferenceModuleOptions?: VideoconferenceModuleOptions;
  knowledgeModuleOptions?: KnowledgeModuleOptions;
  modelRouter?: SmartModelRouterPort;
  onLifecycleReady?: (hooks: {
    initialize: () => Promise<void>;
    shutdown: () => Promise<void>;
  }) => void;
}

export const createApiRouter = (options: ApiRouterOptions = {}): Router => {
  const router = Router();
  const env = getEnv();

  // Single shared SmartModelRouter + GpuTaskSemaphore(AI_MAX_CONCURRENT_JOBS)
  // guarding the local RTX 4060 GPU across all AI features.
  const sharedModelRouter =
    options.modelRouter ??
    new SmartModelRouterAdapter(undefined, {
      maxConcurrentGpu: env.AI_MAX_CONCURRENT_JOBS,
    });

  // 1. Authentication module (/api/v1/auth)
  const authModule = createAuthModule(options.authModuleOptions);
  router.use('/auth', authModule.router);

  // Shared auth chain for admin-guarded modules: every new module below
  // reuses the auth module's middleware (single source of token truth).
  const adminGuard = {
    authenticateMiddleware: authModule.authenticateMiddleware,
    requireAdminMiddleware: authModule.requireRoleMiddleware(['ADMIN'] as Role[]),
  };
  const approvedTeacherMiddleware = authModule.requireApprovedTeacherMiddleware([
    'TEACHER',
    'ADMIN',
  ] as Role[]);

  // 2. Users directory + role management (/api/v1/users).
  const usersModule = createUsersModule({
    ...options.usersModuleOptions,
    ...adminGuard,
    authRepository: options.usersModuleOptions?.authRepository ?? authModule.authRepository,
    tokenService: options.usersModuleOptions?.tokenService ?? authModule.tokenService,
  });
  router.use('/users', usersModule.router);

  // 2b. Admin overview aggregates (/api/v1/admin).
  const adminModule = createAdminModule({
    ...options.adminModuleOptions,
    ...adminGuard,
  });
  router.use('/admin', adminModule.router);

  // 3. Class groups (/api/v1/groups) - initialized early so Knowledge & Courses can use membership
  const groupsModule = createGroupsModule({
    ...options.groupsModuleOptions,
    ...adminGuard,
  });
  router.use('/groups', groupsModule.router);

  // 3a. Unified SmartClass Knowledge Engine (/api/v1/knowledge)
  const knowledgeModule = createKnowledgeModule({
    ...options.knowledgeModuleOptions,
    groupRepository: options.knowledgeModuleOptions?.groupRepository ?? groupsModule.groupRepository,
    authenticateMiddleware: adminGuard.authenticateMiddleware,
    requireTeacherMiddleware: approvedTeacherMiddleware,
  });
  router.use('/knowledge', knowledgeModule.router);
  options.onLifecycleReady?.({
    initialize: knowledgeModule.initialize,
    shutdown: knowledgeModule.shutdown,
  });

  // 2c. AI course generation (/api/v1/ai, teachers only).
  // Keep explicit custom gateway mocks in hermetic integration tests isolated.
  const useCustomHermeticGateway = Boolean(
    options.aiModuleOptions?.gateway && !options.aiModuleOptions?.modelRouter,
  );
  const sectionMemoryBridge =
    options.aiModuleOptions?.sectionMemory ??
    new KnowledgeSectionMemoryBridge(
      knowledgeModule.indexer,
      knowledgeModule.repository,
      new PrismaSectionMemoryAdapter(undefined, new OllamaEmbeddingAdapter()),
    );

  const aiModule = createAiModule({
    ...options.aiModuleOptions,
    modelRouter: useCustomHermeticGateway
      ? undefined
      : (options.aiModuleOptions?.modelRouter ?? sharedModelRouter),
    checkEmbeddings: useCustomHermeticGateway
      ? undefined
      : (options.aiModuleOptions?.checkEmbeddings ??
          (() => knowledgeModule.embedding.checkHealth())),
    sectionMemory: sectionMemoryBridge,
    knowledgeIndexer: options.aiModuleOptions?.knowledgeIndexer ?? knowledgeModule.indexer,
    knowledgeRetrieval:
      options.aiModuleOptions?.knowledgeRetrieval ?? knowledgeModule.retrieval,
    authenticateMiddleware: adminGuard.authenticateMiddleware,
    requireTeacherMiddleware: approvedTeacherMiddleware,
  });
  router.use('/ai', aiModule.router);

  // 3b. Generated courses (/api/v1/courses): teacher drafts + validation,
  // published reading for enrolled class members.
  const coursesModule = createCoursesModule({
    ...options.coursesModuleOptions,
    groupRepository: groupsModule.groupRepository,
    modelRouter: options.coursesModuleOptions?.modelRouter ?? sharedModelRouter,
    knowledgeIndexer: options.coursesModuleOptions?.knowledgeIndexer ?? knowledgeModule.indexer,
    knowledgeRetrieval:
      options.coursesModuleOptions?.knowledgeRetrieval ?? knowledgeModule.retrieval,
    authenticateMiddleware: adminGuard.authenticateMiddleware,
    requireTeacherMiddleware: approvedTeacherMiddleware,
  });
  router.use('/courses', coursesModule.router);

  // 4. Exams (/api/v1/exams): teacher authoring, student attempts,
  // server grading and anti-fraud monitoring. Admin fraud slice stays scoped.
  const examsModule = createExamsModule({
    ...options.examsModuleOptions,
    modelRouter: options.examsModuleOptions?.modelRouter ?? sharedModelRouter,
    authenticateMiddleware: adminGuard.authenticateMiddleware,
    requireAdminMiddleware: adminGuard.requireAdminMiddleware,
    requireTeacherMiddleware: approvedTeacherMiddleware,
    requireStudentMiddleware: authModule.requireRoleMiddleware(['STUDENT'] as Role[]),
  });
  router.use('/exams', examsModule.router);

  // 5. Videoconference timetable & live sessions slice (/api/v1/videoconference)
  const videoconferenceModule = createVideoconferenceModule({
    ...options.videoconferenceModuleOptions,
    ...adminGuard,
    groupRepository: groupsModule.groupRepository,
    modelRouter: options.videoconferenceModuleOptions?.modelRouter ?? sharedModelRouter,
    knowledgeIndexer:
      options.videoconferenceModuleOptions?.knowledgeIndexer ?? knowledgeModule.indexer,
    knowledgeRetrieval:
      options.videoconferenceModuleOptions?.knowledgeRetrieval ?? knowledgeModule.retrieval,
    requireApprovedTeacherMiddleware: approvedTeacherMiddleware,
  });
  router.use('/videoconference', videoconferenceModule.router);

  return router;
};
