import type { Request, Response, NextFunction } from 'express';
import type { ListFraudReportsUseCase } from '../application/list-fraud-reports.use-case.js';
import type { GetFraudSummaryUseCase } from '../application/get-fraud-summary.use-case.js';
import type { UpdateFraudReportUseCase } from '../application/update-fraud-report.use-case.js';
import { parseSort } from '../../../shared/http/pagination/index.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';
import { fraudSortableFields } from './exams.validation.js';

interface ListFraudReportsValidatedQuery {
  status?: 'UNTREATED' | 'IN_PROGRESS' | 'CLOSED';
  severity?: 'LOW' | 'MEDIUM' | 'HIGH';
  cursor?: string;
  limit: number;
  sort?: string;
}

export class ExamsController {
  constructor(
    private readonly listFraudReportsUseCase: ListFraudReportsUseCase,
    private readonly getFraudSummaryUseCase: GetFraudSummaryUseCase,
    private readonly updateFraudReportUseCase: UpdateFraudReportUseCase,
  ) {}

  public listFraudReports = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const query = validatedQuery<ListFraudReportsValidatedQuery>(req);
      const sort = parseSort(query.sort, fraudSortableFields, {
        field: 'occurredAt',
        order: 'desc',
      });

      const result = await this.listFraudReportsUseCase.execute({
        status: query.status,
        severity: query.severity,
        cursor: query.cursor,
        limit: query.limit,
        sortField: sort.field,
        sortOrder: sort.order,
      });

      res.status(200).json({
        data: result.reports,
        meta: result.meta,
      });
    } catch (err) {
      next(err);
    }
  };

  public getFraudSummary = async (
    _req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.getFraudSummaryUseCase.execute();
      res.status(200).json({
        data: result.summary,
      });
    } catch (err) {
      next(err);
    }
  };

  public updateFraudReport = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const body = req.body as { status: 'IN_PROGRESS' | 'CLOSED'; resolution?: string | null };
      const result = await this.updateFraudReportUseCase.execute(
        req.params.id as string,
        body.status,
        body.resolution ?? null,
      );
      res.status(200).json({
        data: result.report,
      });
    } catch (err) {
      next(err);
    }
  };
}
