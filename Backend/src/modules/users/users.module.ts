import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { UserDirectoryPort } from './domain/user-directory.port.js';
import { PrismaUserDirectoryAdapter } from './infrastructure/prisma-user-directory.adapter.js';
import { ListUsersUseCase } from './application/list-users.use-case.js';
import { UsersController } from './presentation/users.controller.js';
import { createUsersRouter } from './presentation/users.routes.js';

export interface UsersModuleOptions {
  userDirectory?: UserDirectoryPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
}

export interface UsersModule {
  router: Router;
  controller: UsersController;
}

export const createUsersModule = (options: UsersModuleOptions = {}): UsersModule => {
  const userDirectory = options.userDirectory ?? new PrismaUserDirectoryAdapter();
  const listUsersUseCase = new ListUsersUseCase(userDirectory);
  const controller = new UsersController(listUsersUseCase);

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('UsersModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireAdminMiddleware =
    options.requireAdminMiddleware ?? createRequireRoleMiddleware(['ADMIN'] as Role[]);

  const router = createUsersRouter({
    controller,
    authenticateMiddleware,
    requireAdminMiddleware,
  });

  return { router, controller };
};
