import type { CursorPaginationMeta } from '../../../shared/http/pagination/index.js';
import type { FraudReportView } from '../domain/fraud-report.entity.js';
import type {
  FraudRepositoryPort,
  ListFraudReportsQuery,
} from '../domain/fraud-repository.port.js';

export interface ListFraudReportsResult {
  reports: FraudReportView[];
  meta: CursorPaginationMeta;
}

export class ListFraudReportsUseCase {
  constructor(private readonly fraudReports: FraudRepositoryPort) {}

  public async execute(query: ListFraudReportsQuery): Promise<ListFraudReportsResult> {
    const { reports, nextCursor, hasMore } = await this.fraudReports.listFraudReports(query);

    return {
      reports,
      meta: { limit: query.limit, nextCursor, hasMore },
    };
  }
}
