import { getPrismaClient } from '../infrastructure/prisma.js';

export interface RecordAuditParams {
  userId?: string | null;
  action: string;
  targetType: string;
  targetId?: string | null;
  details?: Record<string, unknown>;
}

export interface AuditServicePort {
  record(params: RecordAuditParams): Promise<void>;
}

export class PrismaAuditService implements AuditServicePort {
  public async record(params: RecordAuditParams): Promise<void> {
    try {
      const prisma = getPrismaClient();
      await prisma.auditLog.create({
        data: {
          userId: params.userId ?? null,
          action: params.action,
          targetType: params.targetType,
          targetId: params.targetId ?? null,
          details: (params.details as any) ?? {},
        },
      });
    } catch (err) {
      console.error('[AUDIT_ERROR] Failed to record audit log:', err);
    }
  }
}

export class InMemoryAuditService implements AuditServicePort {
  public logs: RecordAuditParams[] = [];
  public async record(params: RecordAuditParams): Promise<void> {
    this.logs.push(params);
  }
}
