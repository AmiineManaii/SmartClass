import type { Request, Response, NextFunction } from 'express';
import type { ListGroupsUseCase } from '../application/list-groups.use-case.js';
import type { CreateGroupUseCase } from '../application/create-group.use-case.js';
import type { GetGroupUseCase } from '../application/get-group.use-case.js';
import type { AssignStudentsUseCase } from '../application/assign-students.use-case.js';
import type { AssignTeachersUseCase } from '../application/assign-teachers.use-case.js';
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
    private readonly createGroupUseCase: CreateGroupUseCase,
    private readonly getGroupUseCase: GetGroupUseCase,
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
