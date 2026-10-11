import type { FraudSummary } from '../domain/fraud-report.entity.js';
import type { FraudRepositoryPort } from '../domain/fraud-repository.port.js';

export interface GetFraudSummaryResult {
  summary: FraudSummary;
}

export class GetFraudSummaryUseCase {
  constructor(private readonly fraudReports: FraudRepositoryPort) {}

  public async execute(): Promise<GetFraudSummaryResult> {
    const summary = await this.fraudReports.fraudSummary();

    return { summary };
  }
}
