import { Router } from 'express';
import { createAuthModule, type AuthModuleOptions, type Role } from './modules/auth/index.js';
import { createUsersModule, type UsersModuleOptions } from './modules/users/index.js';
import { createGroupsModule, type GroupsModuleOptions } from './modules/groups/index.js';
import { createExamsModule, type ExamsModuleOptions } from './modules/exams/index.js';
import {
  createVideoconferenceModule,
  type VideoconferenceModuleOptions,
} from './modules/videoconference/index.js';

export interface ApiRouterOptions {
  authModuleOptions?: AuthModuleOptions;
  usersModuleOptions?: UsersModuleOptions;
  groupsModuleOptions?: GroupsModuleOptions;
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

  // 2. Users directory (/api/v1/users)
  const usersModule = createUsersModule({
    ...options.usersModuleOptions,
    ...adminGuard,
  });
  router.use('/users', usersModule.router);

  // 3. Class groups (/api/v1/groups)
  const groupsModule = createGroupsModule({
    ...options.groupsModuleOptions,
    ...adminGuard,
  });
  router.use('/groups', groupsModule.router);

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
  // router.use('/courses', courseRoutes);
  // router.use('/collaboration', collaborationRoutes);
  // router.use('/ai-assistant', aiAssistantRoutes);
  // router.use('/notifications', notificationRoutes);

  return router;
};
