import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { GroupRepositoryPort } from './domain/group-repository.port.js';
import { PrismaGroupRepositoryAdapter } from './infrastructure/prisma-group-repository.adapter.js';
import type { AuditServicePort } from '../../shared/audit/audit.service.js';
import { PrismaAuditService } from '../../shared/audit/audit.service.js';
import { ListGroupsUseCase } from './application/list-groups.use-case.js';
import { ListMyGroupsUseCase } from './application/list-my-groups.use-case.js';
import { CreateGroupUseCase } from './application/create-group.use-case.js';
import { GetGroupUseCase } from './application/get-group.use-case.js';
import { UpdateGroupUseCase } from './application/update-group.use-case.js';
import { DeleteGroupUseCase } from './application/delete-group.use-case.js';
import { ListDepartmentsUseCase } from './application/list-departments.use-case.js';
import { ListGroupMembersUseCase } from './application/list-group-members.use-case.js';
import { RemoveMembersUseCase } from './application/remove-members.use-case.js';
import { ListTeacherAssignmentsUseCase } from './application/list-teacher-assignments.use-case.js';
import { RemoveTeacherAssignmentsUseCase } from './application/remove-teacher-assignments.use-case.js';
import { AssignStudentsUseCase } from './application/assign-students.use-case.js';
import { AssignTeachersUseCase } from './application/assign-teachers.use-case.js';
import { GenerateInvitationUseCase } from './application/generate-invitation.use-case.js';
import { RotateInvitationUseCase } from './application/rotate-invitation.use-case.js';
import { RevokeInvitationUseCase } from './application/revoke-invitation.use-case.js';
import { GetInvitationStatusUseCase } from './application/get-invitation-status.use-case.js';
import { JoinClassUseCase } from './application/join-class.use-case.js';
import { LeaveClassUseCase } from './application/leave-class.use-case.js';
import { CreateVirtualClassroomUseCase } from './application/create-virtual-classroom.use-case.js';
import { AddMySubjectUseCase } from './application/add-my-subject.use-case.js';
import { GroupsController } from './presentation/groups.controller.js';
import { createGroupsRouter } from './presentation/groups.routes.js';

export interface GroupsModuleOptions {
  groupRepository?: GroupRepositoryPort;
  auditService?: AuditServicePort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
}

export interface GroupsModule {
  router: Router;
  controller: GroupsController;
  groupRepository: GroupRepositoryPort;
}

export const createGroupsModule = (options: GroupsModuleOptions = {}): GroupsModule => {
  const groupRepository = options.groupRepository ?? new PrismaGroupRepositoryAdapter();
  const auditService = options.auditService ?? new PrismaAuditService();

  const listGroupsUseCase = new ListGroupsUseCase(groupRepository);
  const listMyGroupsUseCase = new ListMyGroupsUseCase(groupRepository);
  const createGroupUseCase = new CreateGroupUseCase(groupRepository);
  const getGroupUseCase = new GetGroupUseCase(groupRepository);
  const updateGroupUseCase = new UpdateGroupUseCase(groupRepository);
  const deleteGroupUseCase = new DeleteGroupUseCase(groupRepository);
  const listDepartmentsUseCase = new ListDepartmentsUseCase(groupRepository);
  const listGroupMembersUseCase = new ListGroupMembersUseCase(groupRepository);
  const removeMembersUseCase = new RemoveMembersUseCase(groupRepository, auditService);
  const listTeacherAssignmentsUseCase = new ListTeacherAssignmentsUseCase(groupRepository);
  const removeTeacherAssignmentsUseCase = new RemoveTeacherAssignmentsUseCase(groupRepository);
  const assignStudentsUseCase = new AssignStudentsUseCase(groupRepository);
  const assignTeachersUseCase = new AssignTeachersUseCase(groupRepository);
  const generateInvitationUseCase = new GenerateInvitationUseCase(groupRepository, auditService);
  const rotateInvitationUseCase = new RotateInvitationUseCase(groupRepository, auditService);
  const revokeInvitationUseCase = new RevokeInvitationUseCase(groupRepository, auditService);
  const getInvitationStatusUseCase = new GetInvitationStatusUseCase(groupRepository);
  const joinClassUseCase = new JoinClassUseCase(groupRepository, auditService);
  const leaveClassUseCase = new LeaveClassUseCase(groupRepository, auditService);
  const createVirtualClassroomUseCase = new CreateVirtualClassroomUseCase(groupRepository, auditService);
  const addMySubjectUseCase = new AddMySubjectUseCase(groupRepository);

  const controller = new GroupsController(
    listGroupsUseCase,
    listMyGroupsUseCase,
    createGroupUseCase,
    getGroupUseCase,
    updateGroupUseCase,
    deleteGroupUseCase,
    listDepartmentsUseCase,
    listGroupMembersUseCase,
    removeMembersUseCase,
    listTeacherAssignmentsUseCase,
    removeTeacherAssignmentsUseCase,
    assignStudentsUseCase,
    assignTeachersUseCase,
    generateInvitationUseCase,
    rotateInvitationUseCase,
    revokeInvitationUseCase,
    getInvitationStatusUseCase,
    joinClassUseCase,
    leaveClassUseCase,
    createVirtualClassroomUseCase,
    addMySubjectUseCase,
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

  return { router, controller, groupRepository };
};
