import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type { Prisma } from '@prisma/client';
import { decodeCursor, encodeCursor } from '../../../shared/http/pagination/index.js';
import type {
  FraudReportView,
  FraudSeverity,
  FraudStatus,
  FraudSummary,
} from '../domain/fraud-report.entity.js';
import type {
  FraudRepositoryPort,
  ListFraudReportsQuery,
} from '../domain/fraud-repository.port.js';

interface RawFraudRow {
  id: string;
  title: string;
  context: string | null;
  severity: string;
  status: string;
  findings: unknown;
  reason: string | null;
  resolution: string | null;
  occurredAt: Date;
  createdAt: Date;
  student: { id: string; firstName: string; lastName: string } | null;
  studentName: string;
  studentCode: string | null;
  classGroup: { id: string; name: string } | null;
  className: string | null;
}

export class PrismaFraudRepositoryAdapter implements FraudRepositoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  private toView(raw: RawFraudRow): FraudReportView {
    const findings = Array.isArray(raw.findings)
      ? raw.findings.filter((item): item is string => typeof item === 'string')
      : [];

    return {
      id: raw.id,
      title: raw.title,
      context: raw.context,
      severity: raw.severity as FraudSeverity,
      status: raw.status as FraudStatus,
      student: raw.student
        ? {
            id: raw.student.id,
            name: `${raw.student.firstName} ${raw.student.lastName}`.trim(),
            code: raw.studentCode,
          }
        : {
            id: '',
            name: raw.studentName,
            code: raw.studentCode,
          },
      classGroup: raw.classGroup ?? (raw.className ? { id: '', name: raw.className } : null),
      findings,
      reason: raw.reason,
      resolution: raw.resolution,
      occurredAt: raw.occurredAt,
      createdAt: raw.createdAt,
    };
  }

  private readonly reportSelect = {
    id: true,
    title: true,
    context: true,
    severity: true,
    status: true,
    findings: true,
    reason: true,
    resolution: true,
    occurredAt: true,
    createdAt: true,
    studentName: true,
    studentCode: true,
    className: true,
    student: { select: { id: true, firstName: true, lastName: true } },
    classGroup: { select: { id: true, name: true } },
  } as const;

  public async listFraudReports(query: ListFraudReportsQuery): Promise<{
    reports: FraudReportView[];
    nextCursor: string | null;
    hasMore: boolean;
  }> {
    const where: Prisma.FraudReportWhereInput = {};
    if (query.status) {
      where.status = query.status;
    }
    if (query.severity) {
      where.severity = query.severity;
    }

    // Keyset on the active sort key (occurredAt|createdAt) + id, in the
    // requested direction. The shared encode/decode primitives carry the
    // key value opaquely.
    const useCreatedAt = query.sortField === 'createdAt';
    const ascending = query.sortOrder === 'asc';
    if (query.cursor) {
      const decoded = decodeCursor(query.cursor);
      const keyFilter = ascending ? { gt: decoded.createdAt } : { lt: decoded.createdAt };
      const idFilter = ascending ? { gt: decoded.id } : { lt: decoded.id };
      const tiebreak = useCreatedAt
        ? { createdAt: decoded.createdAt, id: idFilter }
        : { occurredAt: decoded.createdAt, id: idFilter };
      where.AND = [
        { OR: [useCreatedAt ? { createdAt: keyFilter } : { occurredAt: keyFilter }, tiebreak] },
      ];
    }

    const orderBy: Prisma.FraudReportOrderByWithRelationInput[] = useCreatedAt
      ? [{ createdAt: ascending ? 'asc' : 'desc' }, { id: ascending ? 'asc' : 'desc' }]
      : [{ occurredAt: ascending ? 'asc' : 'desc' }, { id: ascending ? 'asc' : 'desc' }];

    const rows = await this.prisma.fraudReport.findMany({
      where,
      orderBy,
      take: query.limit + 1,
      select: this.reportSelect,
    });

    const hasMore = rows.length > query.limit;
    const page = hasMore ? rows.slice(0, query.limit) : rows;
    const last = page[page.length - 1];
    const nextCursor =
      hasMore && last
        ? encodeCursor(useCreatedAt ? last.createdAt : last.occurredAt, last.id)
        : null;

    return {
      reports: page.map((row) => this.toView(row)),
      nextCursor,
      hasMore,
    };
  }

  public async fraudSummary(now: Date = new Date()): Promise<FraudSummary> {
    const monthStart = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));

    const [untreated, inProgress, closed, resolvedThisMonth] = await Promise.all([
      this.prisma.fraudReport.count({ where: { status: 'UNTREATED' } }),
      this.prisma.fraudReport.count({ where: { status: 'IN_PROGRESS' } }),
      this.prisma.fraudReport.count({ where: { status: 'CLOSED' } }),
      this.prisma.fraudReport.count({
        where: { status: 'CLOSED', closedAt: { gte: monthStart } },
      }),
    ]);

    return { untreated, inProgress, closed, resolvedThisMonth };
  }

  public async findFraudReportById(id: string): Promise<FraudReportView | null> {
    const row = await this.prisma.fraudReport.findUnique({
      where: { id },
      select: this.reportSelect,
    });
    if (!row) return null;

    return this.toView(row);
  }

  public async updateFraudReportStatus(
    id: string,
    status: 'IN_PROGRESS' | 'CLOSED',
    resolution?: string | null,
  ): Promise<FraudReportView> {
    const row = await this.prisma.fraudReport.update({
      where: { id },
      data: {
        status,
        resolution: resolution ?? undefined,
        closedAt: status === 'CLOSED' ? new Date() : null,
      },
      select: this.reportSelect,
    });

    return this.toView(row);
  }
}
