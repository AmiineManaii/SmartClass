import type { Request, Response, NextFunction } from 'express';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import type { ListUsersUseCase } from '../application/list-users.use-case.js';
import type { SetMyRoleUseCase } from '../application/set-my-role.use-case.js';
import type { Role } from '../../auth/index.js';
import type { SetUserRoleUseCase } from '../application/set-user-role.use-case.js';
import { getOffsetPaginationParams } from '../../../shared/http/pagination/index.js';
import { parseSort } from '../../../shared/http/pagination/index.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';
import { userSortableFields } from './users.validation.js';

import type { UpdateTeacherApprovalUseCase } from '../application/update-teacher-approval.use-case.js';
import type { TeacherApprovalStatus } from '../../auth/index.js';
import type { ExportUserDataUseCase } from '../application/export-user-data.use-case.js';
import { PdfExportGenerator } from '../infrastructure/pdf-export-generator.js';

interface ListUsersValidatedQuery {
  role?: 'TEACHER' | 'STUDENT' | 'ADMIN';
  search?: string;
  page: number;
  limit: number;
  sort?: string;
}

export class UsersController {
  constructor(
    private readonly listUsersUseCase: ListUsersUseCase,
    private readonly setMyRoleUseCase: SetMyRoleUseCase,
    private readonly setUserRoleUseCase: SetUserRoleUseCase,
    private readonly updateTeacherApprovalUseCase?: UpdateTeacherApprovalUseCase,
    private readonly exportUserDataUseCase?: ExportUserDataUseCase,
    private readonly pdfExportGenerator: PdfExportGenerator = new PdfExportGenerator(),
  ) {}

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

  public setMyRole = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.setMyRoleUseCase.execute(
        req.user.id,
        (req.body as { role: string }).role,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public setUserRole = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const result = await this.setUserRoleUseCase.execute(
        req.user.id,
        req.params.id as string,
        (req.body as { role: Role }).role,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public updateTeacherApproval = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.updateTeacherApprovalUseCase) {
        throw new Error('UpdateTeacherApprovalUseCase not configured');
      }
      const result = await this.updateTeacherApprovalUseCase.execute(
        req.user.id,
        req.params.id as string,
        (req.body as { status: TeacherApprovalStatus }).status,
      );
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public exportData = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      if (!this.exportUserDataUseCase) {
        throw new Error('ExportUserDataUseCase not configured');
      }

      const format = (req.query.format as string)?.toLowerCase() === 'pdf' ? 'pdf' : 'json';
      const data = await this.exportUserDataUseCase.execute({
        userId: req.user.id,
        role: (req.user.role as Role) ?? null,
      });

      const safeLastName = (data.user.lastName || 'user').replace(/[^a-zA-Z0-9_-]/g, '_');
      const safeFirstName = (data.user.firstName || 'export').replace(/[^a-zA-Z0-9_-]/g, '_');
      const dateStr = new Date().toISOString().slice(0, 10);

      if (format === 'pdf') {
        const pdfBuffer = await this.pdfExportGenerator.generatePdf(data);
        res.setHeader('Content-Type', 'application/pdf');
        res.setHeader(
          'Content-Disposition',
          `attachment; filename="smartclass_export_${safeLastName}_${safeFirstName}_${dateStr}.pdf"`,
        );
        res.setHeader('Content-Length', pdfBuffer.length);
        res.status(200).send(pdfBuffer);
        return;
      }

      // JSON format
      res.setHeader('Content-Type', 'application/json; charset=utf-8');
      res.setHeader(
        'Content-Disposition',
        `attachment; filename="smartclass_export_${safeLastName}_${safeFirstName}_${dateStr}.json"`,
      );
      res.status(200).json(data);
    } catch (err) {
      next(err);
    }
  };
}
