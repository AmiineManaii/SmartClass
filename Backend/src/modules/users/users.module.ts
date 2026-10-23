import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { AuthRepositoryPort } from '../auth/index.js';
import type { UserDirectoryPort } from './domain/user-directory.port.js';
import { PrismaUserDirectoryAdapter } from './infrastructure/prisma-user-directory.adapter.js';
import { ListUsersUseCase } from './application/list-users.use-case.js';
import { SetMyRoleUseCase } from './application/set-my-role.use-case.js';
import { SetUserRoleUseCase } from './application/set-user-role.use-case.js';
import { UpdateTeacherApprovalUseCase } from './application/update-teacher-approval.use-case.js';
import { PrismaAuditService, type AuditServicePort } from '../../shared/audit/audit.service.js';
import { UsersController } from './presentation/users.controller.js';
import { createUsersRouter } from './presentation/users.routes.js';

import type { ExportDataPort } from './domain/export-data.port.js';
import { PrismaExportDataAdapter } from './infrastructure/prisma-export-data.adapter.js';
import { ExportUserDataUseCase } from './application/export-user-data.use-case.js';

export interface UsersModuleOptions {
  userDirectory?: UserDirectoryPort;
  exportDataPort?: ExportDataPort;
  authRepository?: AuthRepositoryPort;
  tokenService?: TokenServicePort;
  auditService?: AuditServicePort;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
  refreshExpirationDays?: number;
}

export interface UsersModule {
  router: Router;
  controller: UsersController;
}

export const createUsersModule = (options: UsersModuleOptions = {}): UsersModule => {
  const userDirectory = options.userDirectory ?? new PrismaUserDirectoryAdapter();
  const listUsersUseCase = new ListUsersUseCase(userDirectory);

  // Role endpoints mint fresh tokens on change: they need the auth internals
  // (shared from the auth module in routes.ts, never duplicated here).
  const authRepository = options.authRepository;
  const tokenService = options.tokenService;
  if (!authRepository || !tokenService) {
    throw new Error('UsersModule requires authRepository and tokenService for role endpoints');
  }
  const auditService = options.auditService ?? new PrismaAuditService();
  const setMyRoleUseCase = new SetMyRoleUseCase(
    authRepository,
    tokenService,
    options.refreshExpirationDays,
  );
  const setUserRoleUseCase = new SetUserRoleUseCase(authRepository);
  const updateTeacherApprovalUseCase = new UpdateTeacherApprovalUseCase(authRepository, auditService);
  const exportDataPort = options.exportDataPort ?? new PrismaExportDataAdapter();
  const exportUserDataUseCase = new ExportUserDataUseCase(exportDataPort);
  const controller = new UsersController(
    listUsersUseCase,
    setMyRoleUseCase,
    setUserRoleUseCase,
    updateTeacherApprovalUseCase,
    exportUserDataUseCase,
  );

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
