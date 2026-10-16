import { Router } from 'express';
import { createAuthModule, type AuthModuleOptions, type Role } from './modules/auth/index.js';
import { createUsersModule, type UsersModuleOptions } from './modules/users/index.js';
import { createAdminModule, type AdminModuleOptions } from './modules/admin/index.js';
import { createAiModule, type AiModuleOptions } from './modules/ai-assistant/index.js';
import { createGroupsModule, type GroupsModuleOptions } from './modules/groups/index.js';
import { createCoursesModule, type CoursesModuleOptions } from './modules/courses/index.js';
import { createExamsModule, type ExamsModuleOptions } from './modules/exams/index.js';
import {
  createVideoconferenceModule,
  type VideoconferenceModuleOptions,
} from './modules/videoconference/index.js';

export interface ApiRouterOptions {
  authModuleOptions?: AuthModuleOptions;
  usersModuleOptions?: UsersModuleOptions;
  adminModuleOptions?: AdminModuleOptions;
  aiModuleOptions?: AiModuleOptions;
  groupsModuleOptions?: GroupsModuleOptions;
  coursesModuleOptions?: CoursesModuleOptions;
  examsModuleOptions?: ExamsModuleOptions;
  videoconferenceModuleOptions?: VideoconferenceModuleOptions;
}

export const createApiRouter = (options: ApiRouterOptions = {}): Router => {
  const router = Router();

  // 1. Authentication module (/api/v1/auth)
  const authModule = createAuthModule(options.authModuleOptions);
  router.use('/auth', authModule.router);

  // Shared auth chain for admin-guarded modules: every new module below
  // reuses the auth module's middleware (single source of token truth).
  const adminGuard = {
    authenticateMiddleware: authModule.authenticateMiddleware,
    requireAdminMiddleware: authModule.requireRoleMiddleware(['ADMIN'] as Role[]),
  };

  // 2. Users directory + role management (/api/v1/users).
  // Role endpoints need the auth internals (token issuance on role change),
  // shared from the auth module rather than duplicated.
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

  // 2c. AI course generation (local LLM gateway, teachers only).
  const aiModule = createAiModule({
    ...options.aiModuleOptions,
    authenticateMiddleware: adminGuard.authenticateMiddleware,
    requireTeacherMiddleware: authModule.requireApprovedTeacherMiddleware(['TEACHER', 'ADMIN'] as Role[]),
  });
  router.use('/ai', aiModule.router);

  // 3. Class groups (/api/v1/groups)
  const groupsModule = createGroupsModule({
    ...options.groupsModuleOptions,
    ...adminGuard,
  });
  router.use('/groups', groupsModule.router);

  // 3b. Generated courses (/api/v1/courses): teacher drafts + validation,
  // published reading for every authenticated user.
  const coursesModule = createCoursesModule({
    ...options.coursesModuleOptions,
    groupRepository: groupsModule.groupRepository,
    authenticateMiddleware: adminGuard.authenticateMiddleware,
    requireTeacherMiddleware: authModule.requireApprovedTeacherMiddleware(['TEACHER', 'ADMIN'] as Role[]),
  });
  router.use('/courses', coursesModule.router);

  // 4. Exams integrity slice (/api/v1/exams)
  const examsModule = createExamsModule({
    ...options.examsModuleOptions,
    ...adminGuard,
  });
  router.use('/exams', examsModule.router);

  // 5. Videoconference timetable slice (/api/v1/videoconference)
  const videoconferenceModule = createVideoconferenceModule({
    ...options.videoconferenceModuleOptions,
    ...adminGuard,
  });
  router.use('/videoconference', videoconferenceModule.router);

  // Future bounded context modules will be mounted here:
  // router.use('/collaboration', collaborationRoutes);
  // router.use('/ai-assistant', aiAssistantRoutes);
  // router.use('/notifications', notificationRoutes);

  return router;
};
