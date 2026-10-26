import type { SessionParticipant } from '../domain/video-session.entity.js';
import type { SessionParticipantRepositoryPort } from '../domain/session-participant-repository.port.js';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';

export class PrismaSessionParticipantRepositoryAdapter
  implements SessionParticipantRepositoryPort
{
  constructor(private readonly prisma = getPrismaClient()) {}

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapToDomain(row: any): SessionParticipant {
    const userDisplayName =
      row.user && typeof row.user.firstName === 'string' && typeof row.user.lastName === 'string'
        ? `${row.user.firstName} ${row.user.lastName}`
        : null;

    return {
      id: row.id,
      sessionId: row.sessionId,
      userId: row.userId,
      userDisplayName,
      userRole: row.user?.role ?? null,
      joinedAt: row.joinedAt,
      leftAt: row.leftAt,
    };
  }

  public async recordJoin(
    sessionId: string,
    userId: string,
    joinedAt: Date,
  ): Promise<SessionParticipant> {
    const row = await this.prisma.sessionParticipant.create({
      data: {
        sessionId,
        userId,
        joinedAt,
      },
      include: {
        user: {
          select: { firstName: true, lastName: true, role: true },
        },
      },
    });

    return this.mapToDomain(row);
  }

  public async recordLeave(
    sessionId: string,
    userId: string,
    leftAt: Date,
  ): Promise<SessionParticipant | null> {
    const latest = await this.prisma.sessionParticipant.findFirst({
      where: {
        sessionId,
        userId,
        leftAt: null,
      },
      orderBy: { joinedAt: 'desc' },
    });

    if (!latest) {
      return null;
    }

    const updated = await this.prisma.sessionParticipant.update({
      where: { id: latest.id },
      data: { leftAt },
      include: {
        user: {
          select: { firstName: true, lastName: true, role: true },
        },
      },
    });

    return this.mapToDomain(updated);
  }

  public async listBySession(sessionId: string): Promise<SessionParticipant[]> {
    const rows = await this.prisma.sessionParticipant.findMany({
      where: { sessionId },
      include: {
        user: {
          select: { firstName: true, lastName: true, role: true },
        },
      },
      orderBy: { joinedAt: 'asc' },
    });

    return rows.map((r) => this.mapToDomain(r));
  }

  public async countActiveBySession(sessionId: string): Promise<number> {
    return this.prisma.sessionParticipant.count({
      where: {
        sessionId,
        leftAt: null,
      },
    });
  }
}
