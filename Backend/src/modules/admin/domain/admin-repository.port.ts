import type { AdminOverview } from './admin-overview.entity.js';

export interface AdminRepositoryPort {
  getOverview(monthStart: Date): Promise<AdminOverview>;
}
