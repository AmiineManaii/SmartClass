import type { AdminOverview } from '../domain/admin-overview.entity.js';
import type { AdminRepositoryPort } from '../domain/admin-repository.port.js';

export interface GetOverviewResult {
  overview: AdminOverview;
}

export class GetOverviewUseCase {
  constructor(private readonly adminRepository: AdminRepositoryPort) {}

  public async execute(now: Date = new Date()): Promise<GetOverviewResult> {
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
    const overview = await this.adminRepository.getOverview(monthStart);

    return { overview };
  }
}
