import type {
  FraudReportView,
  FraudSeverity,
  FraudStatus,
  FraudSummary,
} from './fraud-report.entity.js';

export interface ListFraudReportsQuery {
  status?: FraudStatus;
  severity?: FraudSeverity;
  cursor?: string;
  limit: number;
  sortField: 'occurredAt' | 'createdAt';
  sortOrder: 'asc' | 'desc';
}

export interface FraudRepositoryPort {
  listFraudReports(query: ListFraudReportsQuery): Promise<{
    reports: FraudReportView[];
    nextCursor: string | null;
    hasMore: boolean;
  }>;
  fraudSummary(now?: Date): Promise<FraudSummary>;
  findFraudReportById(id: string): Promise<FraudReportView | null>;
  updateFraudReportStatus(
    id: string,
    status: 'IN_PROGRESS' | 'CLOSED',
    resolution?: string | null,
  ): Promise<FraudReportView>;
}
