import type { SessionParticipantRemoval } from '../domain/video-session.entity.js';
import type { SessionRemovalRepositoryPort } from '../domain/session-removal-repository.port.js';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';

export class PrismaSessionRemovalRepositoryAdapter implements SessionRemovalRepositoryPort {
  constructor(private readonly prisma = getPrismaClient()) {}

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapToDomain(row: any): SessionParticipantRemoval {
    return {
      id: row.id,
      sessionId: row.sessionId,
      userId: row.userId,
      removedById: row.removedById,
      reason: row.reason,
      removedAt: row.removedAt,
    };
  }

  public async recordRemoval(
    removal: Omit<SessionParticipantRemoval, 'id' | 'removedAt'>,
  ): Promise<SessionParticipantRemoval> {
    const row = await this.prisma.sessionParticipantRemoval.upsert({
      where: {
        sessionId_userId: {
          sessionId: removal.sessionId,
          userId: removal.userId,
        },
      },
      create: {
        sessionId: removal.sessionId,
        userId: removal.userId,
        removedById: removal.removedById,
        reason: removal.reason,
      },
      update: {
        removedById: removal.removedById,
        reason: removal.reason,
        removedAt: new Date(),
      },
    });

    return this.mapToDomain(row);
  }

  public async isUserRemoved(sessionId: string, userId: string): Promise<boolean> {
    const found = await this.prisma.sessionParticipantRemoval.findUnique({
      where: {
        sessionId_userId: {
          sessionId,
          userId,
        },
      },
      select: { id: true },
    });

    return Boolean(found);
  }
}
