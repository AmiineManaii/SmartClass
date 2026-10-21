import type { AuthRepositoryPort } from '../domain/auth-repository.port.js';

export interface AuditLogItem {
  id: string;
  action: string;
  targetType: string;
  targetId: string | null;
  details: unknown;
  createdAt: string;
}

export class GetAuditLogsUseCase {
  constructor(private readonly authRepository: AuthRepositoryPort) {}

  public async execute(userId: string, limit: number = 20): Promise<AuditLogItem[]> {
    const logs = await this.authRepository.getUserAuditLogs(userId, limit);
    return logs.map((log) => ({
      id: log.id,
      action: log.action,
      targetType: log.targetType,
      targetId: log.targetId,
      details: log.details,
      createdAt: log.createdAt.toISOString(),
    }));
  }
}
