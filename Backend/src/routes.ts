import { Router } from 'express';
import { createAuthModule, type AuthModuleOptions } from './modules/auth/index.js';

export interface ApiRouterOptions {
  authModuleOptions?: AuthModuleOptions;
}

export const createApiRouter = (options: ApiRouterOptions = {}): Router => {
  const router = Router();

  // 1. Authentication module (/api/v1/auth)
  const authModule = createAuthModule(options.authModuleOptions);
  router.use('/auth', authModule.router);

  // Future bounded context modules will be mounted here:
  // router.use('/groups', groupRoutes);
  // router.use('/courses', courseRoutes);
  // router.use('/exams', examRoutes);
  // router.use('/videoconference', videoconferenceRoutes);
  // router.use('/collaboration', collaborationRoutes);
  // router.use('/ai-assistant', aiAssistantRoutes);
  // router.use('/notifications', notificationRoutes);

  return router;
};
