import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { GroupRepositoryPort } from './domain/group-repository.port.js';
import { PrismaGroupRepositoryAdapter } from './infrastructure/prisma-group-repository.adapter.js';
import { ListGroupsUseCase } from './application/list-groups.use-case.js';
import { CreateGroupUseCase } from './application/create-group.use-case.js';
import { GetGroupUseCase } from './application/get-group.use-case.js';
import { AssignStudentsUseCase } from './application/assign-students.use-case.js';
import { AssignTeachersUseCase } from './application/assign-teachers.use-case.js';
import { GroupsController } from './presentation/groups.controller.js';
import { createGroupsRouter } from './presentation/groups.routes.js';

export interface GroupsModuleOptions {
  groupRepository?: GroupRepositoryPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
}

export interface GroupsModule {
  router: Router;
  controller: GroupsController;
}

export const createGroupsModule = (options: GroupsModuleOptions = {}): GroupsModule => {
  const groupRepository = options.groupRepository ?? new PrismaGroupRepositoryAdapter();

  const listGroupsUseCase = new ListGroupsUseCase(groupRepository);
  const createGroupUseCase = new CreateGroupUseCase(groupRepository);
  const getGroupUseCase = new GetGroupUseCase(groupRepository);
  const assignStudentsUseCase = new AssignStudentsUseCase(groupRepository);
  const assignTeachersUseCase = new AssignTeachersUseCase(groupRepository);

  const controller = new GroupsController(
    listGroupsUseCase,
    createGroupUseCase,
    getGroupUseCase,
    assignStudentsUseCase,
    assignTeachersUseCase,
  );

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('GroupsModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireAdminMiddleware =
    options.requireAdminMiddleware ?? createRequireRoleMiddleware(['ADMIN'] as Role[]);

  const router = createGroupsRouter({
    controller,
    authenticateMiddleware,
    requireAdminMiddleware,
  });

  return { router, controller };
};
