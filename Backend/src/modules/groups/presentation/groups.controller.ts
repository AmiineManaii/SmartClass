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
      const result = await this.getGroupUseCase.execute(req.params.id as string);
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
}
