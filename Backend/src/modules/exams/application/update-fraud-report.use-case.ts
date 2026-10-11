import { ConflictError, NotFoundError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import type { FraudReportView } from '../domain/fraud-report.entity.js';
import type { FraudRepositoryPort } from '../domain/fraud-repository.port.js';

export interface UpdateFraudReportResult {
  report: FraudReportView;
}

export class UpdateFraudReportUseCase {
  constructor(private readonly fraudReports: FraudRepositoryPort) {}

  public async execute(
    reportId: string,
    status: 'IN_PROGRESS' | 'CLOSED',
    resolution?: string | null,
  ): Promise<UpdateFraudReportResult> {
    const existing = await this.fraudReports.findFraudReportById(reportId);
    if (!existing) {
      throw new NotFoundError('Fraud report not found');
    }

    // Closed reports are terminal (audit integrity, RG21 retention).
    if (existing.status === 'CLOSED') {
      throw new ConflictError(
        'Fraud report is already closed and cannot be reopened',
        ErrorCodes.CONFLICT,
      );
    }

    const report = await this.fraudReports.updateFraudReportStatus(
      reportId,
      status,
      resolution ?? null,
    );

    return { report };
  }
}
