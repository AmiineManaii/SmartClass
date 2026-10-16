import type { Request, Response, NextFunction } from 'express';
import type { ListGroupsUseCase } from '../application/list-groups.use-case.js';
import type { ListMyGroupsUseCase } from '../application/list-my-groups.use-case.js';
import type { CreateGroupUseCase } from '../application/create-group.use-case.js';
import type { GetGroupUseCase } from '../application/get-group.use-case.js';
import type { UpdateGroupUseCase } from '../application/update-group.use-case.js';
import type { DeleteGroupUseCase } from '../application/delete-group.use-case.js';
import type { ListDepartmentsUseCase } from '../application/list-departments.use-case.js';
import type { ListGroupMembersUseCase } from '../application/list-group-members.use-case.js';
import type { RemoveMembersUseCase } from '../application/remove-members.use-case.js';
import type {
  ListTeacherAssignmentsUseCase,
} from '../application/list-teacher-assignments.use-case.js';
import type {
  RemoveTeacherAssignmentsUseCase,
} from '../application/remove-teacher-assignments.use-case.js';
import type { AssignStudentsUseCase } from '../application/assign-students.use-case.js';
import type { AssignTeachersUseCase } from '../application/assign-teachers.use-case.js';
import type { GenerateInvitationUseCase } from '../application/generate-invitation.use-case.js';
import type { RotateInvitationUseCase } from '../application/rotate-invitation.use-case.js';
import type { RevokeInvitationUseCase } from '../application/revoke-invitation.use-case.js';
import type { GetInvitationStatusUseCase } from '../application/get-invitation-status.use-case.js';
import type { JoinClassUseCase } from '../application/join-class.use-case.js';
import type { LeaveClassUseCase } from '../application/leave-class.use-case.js';
import type { CreateVirtualClassroomUseCase } from '../application/create-virtual-classroom.use-case.js';
import type { UpdateGroupParams } from '../domain/group-repository.port.js';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import { getOffsetPaginationParams } from '../../../shared/http/pagination/index.js';
import { parseSort } from '../../../shared/http/pagination/index.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';
import { groupSortableFields } from './groups.validation.js';

interface ListGroupsValidatedQuery {
  level?: 'LICENCE' | 'MASTER' | 'DOCTORAT';
  search?: string;
  page: number;
  limit: number;
  sort?: string;
}

export class GroupsController {
  constructor(
    private readonly listGroupsUseCase: ListGroupsUseCase,
    private readonly listMyGroupsUseCase: ListMyGroupsUseCase,
    private readonly createGroupUseCase: CreateGroupUseCase,
    private readonly getGroupUseCase: GetGroupUseCase,
    private readonly updateGroupUseCase: UpdateGroupUseCase,
    private readonly deleteGroupUseCase: DeleteGroupUseCase,
    private readonly listDepartmentsUseCase: ListDepartmentsUseCase,
    private readonly listGroupMembersUseCase: ListGroupMembersUseCase,
    private readonly removeMembersUseCase: RemoveMembersUseCase,
    private readonly listTeacherAssignmentsUseCase: ListTeacherAssignmentsUseCase,
    private readonly removeTeacherAssignmentsUseCase: RemoveTeacherAssignmentsUseCase,
    private readonly assignStudentsUseCase: AssignStudentsUseCase,
    private readonly assignTeachersUseCase: AssignTeachersUseCase,
    private readonly generateInvitationUseCase?: GenerateInvitationUseCase,
    private readonly rotateInvitationUseCase?: RotateInvitationUseCase,
    private readonly revokeInvitationUseCase?: RevokeInvitationUseCase,
    private readonly getInvitationStatusUseCase?: GetInvitationStatusUseCase,
    private readonly joinClassUseCase?: JoinClassUseCase,
    private readonly leaveClassUseCase?: LeaveClassUseCase,
    private readonly createVirtualClassroomUseCase?: CreateVirtualClassroomUseCase,
  ) {}

  public listGroups = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const query = validatedQuery<ListGroupsValidatedQuery>(req);
      const { page, limit } = getOffsetPaginationParams({
        page: query.page,
        limit: query.limit,
      });
      const sort = parseSort(query.sort, groupSortableFields, {
        field: 'createdAt',
        order: 'desc',
      });

      const result = await this.listGroupsUseCase.execute({
        level: query.level,
        search: query.search,
        page,
        limit,
        sortField: sort.field,
        sortOrder: sort.order,
      });

      res.status(200).json({
        data: result.groups,
        meta: result.meta,
      });
    } catch (err) {
      next(err);
    }
  };

  public listMyGroups = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.listMyGroupsUseCase.execute(req.user.id);
      res.status(200).json({
        data: result.groups,
      });
    } catch (err) {
      next(err);
    }
  };

  public createGroup = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.createGroupUseCase.execute(req.body);
      res.status(201).json({
        data: result.group,
      });
    } catch (err) {
      next(err);
    }
  };

  public getGroup = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.getGroupUseCase.execute(
        req.params.id as string,
        req.user?.id,
        req.user?.role ?? undefined,
      );
      res.status(200).json({
        data: result.group,
      });
    } catch (err) {
      next(err);
    }
  };

  public updateGroup = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.updateGroupUseCase.execute(
        req.params.id as string,
        req.body as UpdateGroupParams,
      );
      res.status(200).json({
        data: result.group,
      });
    } catch (err) {
      next(err);
    }
  };

  public deleteGroup = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      await this.deleteGroupUseCase.execute(req.params.id as string);
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  };

  public listDepartments = async (
    _req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.listDepartmentsUseCase.execute();
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public listMembers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const query = validatedQuery<{ page: number; limit: number }>(req);
      const { page, limit } = getOffsetPaginationParams({
        page: query.page,
        limit: query.limit,
      });
      const result = await this.listGroupMembersUseCase.execute(
        req.params.id as string,
        page,
        limit,
        req.user?.id,
        req.user?.role ?? undefined,
      );
      res.status(200).json({
        data: result.members,
        meta: result.meta,
      });
    } catch (err) {
      next(err);
    }
  };

  public removeMembers = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.removeMembersUseCase.execute(
        req.params.id as string,
        (req.body as { studentIds: string[] }).studentIds,
        req.user?.id,
        req.user?.role ?? undefined,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public listTeachers = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.listTeacherAssignmentsUseCase.execute(
        req.params.id as string,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public removeTeachers = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.removeTeacherAssignmentsUseCase.execute(
        req.params.id as string,
        (req.body as { teacherIds: string[] }).teacherIds,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public assignStudents = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.assignStudentsUseCase.execute(
        req.params.id as string,
        (req.body as { studentIds: string[] }).studentIds,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public assignTeachers = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.assignTeachersUseCase.execute(
        req.params.id as string,
        (
          req.body as {
            assignments: { teacherId: string; subject: string; weeklyHours?: string | null }[];
          }
        ).assignments,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public generateInvitation = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!this.generateInvitationUseCase) {
        throw new Error('generateInvitationUseCase not configured');
      }
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const body = req.body as { expiresInHours?: number | null; maxUses?: number | null };
      const result = await this.generateInvitationUseCase.execute({
        groupId: req.params.id as string,
        actorId: req.user.id,
        actorRole: req.user.role ?? '',
        expiresInHours: body?.expiresInHours,
        maxUses: body?.maxUses,
      });
      res.status(201).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public rotateInvitation = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!this.rotateInvitationUseCase) {
        throw new Error('rotateInvitationUseCase not configured');
      }
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const body = req.body as { expiresInHours?: number | null; maxUses?: number | null };
      const result = await this.rotateInvitationUseCase.execute({
        groupId: req.params.id as string,
        actorId: req.user.id,
        actorRole: req.user.role ?? '',
        expiresInHours: body?.expiresInHours,
        maxUses: body?.maxUses,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public revokeInvitation = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!this.revokeInvitationUseCase) {
        throw new Error('revokeInvitationUseCase not configured');
      }
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.revokeInvitationUseCase.execute({
        groupId: req.params.id as string,
        actorId: req.user.id,
        actorRole: req.user.role ?? '',
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public getInvitationStatus = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!this.getInvitationStatusUseCase) {
        throw new Error('getInvitationStatusUseCase not configured');
      }
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.getInvitationStatusUseCase.execute({
        groupId: req.params.id as string,
        actorId: req.user.id,
        actorRole: req.user.role ?? '',
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public joinClass = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!this.joinClassUseCase) {
        throw new Error('joinClassUseCase not configured');
      }
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const body = req.body as { code: string };
      const result = await this.joinClassUseCase.execute({
        rawCode: body.code,
        studentId: req.user.id,
        studentRole: req.user.role ?? '',
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public leaveClass = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!this.leaveClassUseCase) {
        throw new Error('leaveClassUseCase not configured');
      }
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.leaveClassUseCase.execute({
        groupId: req.params.id as string,
        studentId: req.user.id,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public createVirtualClassroom = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      if (!this.createVirtualClassroomUseCase) {
        throw new Error('createVirtualClassroomUseCase not configured');
      }
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const body = req.body as { name: string; capacity?: number; description?: string | null };
      const result = await this.createVirtualClassroomUseCase.execute({
        teacherId: req.user.id,
        teacherRole: req.user.role ?? '',
        name: body.name,
        capacity: body.capacity,
        description: body.description,
      });
      res.status(201).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };
}
