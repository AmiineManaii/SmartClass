import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { AdminRepositoryPort } from './domain/admin-repository.port.js';
import { PrismaAdminRepositoryAdapter } from './infrastructure/prisma-admin-repository.adapter.js';
import { GetOverviewUseCase } from './application/get-overview.use-case.js';
import { AdminController } from './presentation/admin.controller.js';
import { createAdminRouter } from './presentation/admin.routes.js';

export interface AdminModuleOptions {
  adminRepository?: AdminRepositoryPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
}

export interface AdminModule {
  router: Router;
  controller: AdminController;
}

export const createAdminModule = (options: AdminModuleOptions = {}): AdminModule => {
  const adminRepository = options.adminRepository ?? new PrismaAdminRepositoryAdapter();
  const getOverviewUseCase = new GetOverviewUseCase(adminRepository);
  const controller = new AdminController(getOverviewUseCase);

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('AdminModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireAdminMiddleware =
    options.requireAdminMiddleware ?? createRequireRoleMiddleware(['ADMIN'] as Role[]);

  const router = createAdminRouter({
    controller,
    authenticateMiddleware,
    requireAdminMiddleware,
  });

  return { router, controller };
};
