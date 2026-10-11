import type { Request, Response, NextFunction } from 'express';
import type { ListUsersUseCase } from '../application/list-users.use-case.js';
import { getOffsetPaginationParams } from '../../../shared/http/pagination/index.js';
import { parseSort } from '../../../shared/http/pagination/index.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';
import { userSortableFields } from './users.validation.js';

interface ListUsersValidatedQuery {
  role?: 'TEACHER' | 'STUDENT' | 'ADMIN';
  search?: string;
  page: number;
  limit: number;
  sort?: string;
}

export class UsersController {
  constructor(private readonly listUsersUseCase: ListUsersUseCase) {}

  public listUsers = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const query = validatedQuery<ListUsersValidatedQuery>(req);
      const { page, limit } = getOffsetPaginationParams({
        page: query.page,
        limit: query.limit,
      });
      const sort = parseSort(query.sort, userSortableFields, {
        field: 'createdAt',
        order: 'desc',
      });

      const result = await this.listUsersUseCase.execute({
        role: query.role,
        search: query.search,
        page,
        limit,
        sortField: sort.field,
        sortOrder: sort.order,
      });

      res.status(200).json({
        data: result.users,
        meta: result.meta,
      });
    } catch (err) {
      next(err);
    }
  };
}
