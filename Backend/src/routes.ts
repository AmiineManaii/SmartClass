import { Router } from 'express';

export const createApiRouter = (): Router => {
  const router = Router();

  // Future bounded context modules will be mounted here:
  // router.use('/auth', authRoutes);
  // router.use('/users', userRoutes);
  // router.use('/groups', groupRoutes);
  // router.use('/courses', courseRoutes);
  // router.use('/exams', examRoutes);
  // router.use('/videoconference', videoconferenceRoutes);
  // router.use('/collaboration', collaborationRoutes);
  // router.use('/ai-assistant', aiAssistantRoutes);
  // router.use('/notifications', notificationRoutes);

  return router;
};
