import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { TimetableRepositoryPort } from './domain/timetable-repository.port.js';
import { PrismaTimetableRepositoryAdapter } from './infrastructure/prisma-timetable-repository.adapter.js';
import { GetTimetableWeekUseCase } from './application/get-timetable-week.use-case.js';
import { VideoconferenceController } from './presentation/videoconference.controller.js';
import { createVideoconferenceRouter } from './presentation/videoconference.routes.js';

export interface VideoconferenceModuleOptions {
  timetableRepository?: TimetableRepositoryPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
}

export interface VideoconferenceModule {
  router: Router;
  controller: VideoconferenceController;
}

export const createVideoconferenceModule = (
  options: VideoconferenceModuleOptions = {},
): VideoconferenceModule => {
  const timetableRepository = options.timetableRepository ?? new PrismaTimetableRepositoryAdapter();
  const getTimetableWeekUseCase = new GetTimetableWeekUseCase(timetableRepository);
  const controller = new VideoconferenceController(getTimetableWeekUseCase);

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('VideoconferenceModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireAdminMiddleware =
    options.requireAdminMiddleware ?? createRequireRoleMiddleware(['ADMIN'] as Role[]);

  const router = createVideoconferenceRouter({
    controller,
    authenticateMiddleware,
    requireAdminMiddleware,
  });

  return { router, controller };
};
