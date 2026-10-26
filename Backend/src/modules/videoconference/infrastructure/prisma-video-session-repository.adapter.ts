import type { PrismaClient } from '@prisma/client';
import type {
  VideoSession,
  VideoSessionStatus,
} from '../domain/video-session.entity.js';
import type {
  VideoSessionRepositoryPort,
  VideoSessionListFilter,
} from '../domain/video-session-repository.port.js';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';

export class PrismaVideoSessionRepositoryAdapter implements VideoSessionRepositoryPort {
  constructor(private readonly prisma: PrismaClient = getPrismaClient()) {}

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  private mapToDomain(row: any): VideoSession {
    const hostName =
      row.host && typeof row.host.firstName === 'string' && typeof row.host.lastName === 'string'
        ? `${row.host.firstName} ${row.host.lastName}`
        : null;

    return {
      id: row.id,
      classGroupId: row.classGroupId,
      hostId: row.hostId,
      hostName,
      subject: row.subject,
      title: row.title,
      description: row.description,
      startsAt: row.startsAt,
      endsAt: row.endsAt,
      startedAt: row.startedAt,
      endedAt: row.endedAt,
      status: row.status as VideoSessionStatus,
      roomName: row.roomName,
      joinOpensMinutesBefore: row.joinOpensMinutesBefore,
      chatEnabled: row.chatEnabled,
      timetableSlotId: row.timetableSlotId,
      courseId: row.courseId,
      cancelReason: row.cancelReason,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  public async create(session: VideoSession): Promise<VideoSession> {
    const created = await this.prisma.videoSession.create({
      data: {
        id: session.id,
        classGroupId: session.classGroupId,
        hostId: session.hostId,
        subject: session.subject,
        title: session.title,
        description: session.description,
        startsAt: session.startsAt,
        endsAt: session.endsAt,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        status: session.status,
        roomName: session.roomName,
        joinOpensMinutesBefore: session.joinOpensMinutesBefore,
        chatEnabled: session.chatEnabled,
        timetableSlotId: session.timetableSlotId,
        courseId: session.courseId,
        cancelReason: session.cancelReason,
      },
      include: {
        host: {
          select: { firstName: true, lastName: true },
        },
      },
    });

    return this.mapToDomain(created);
  }

  public async findById(id: string): Promise<VideoSession | null> {
    const row = await this.prisma.videoSession.findUnique({
      where: { id },
      include: {
        host: {
          select: { firstName: true, lastName: true },
        },
      },
    });

    return row ? this.mapToDomain(row) : null;
  }

  public async findByRoomName(roomName: string): Promise<VideoSession | null> {
    const row = await this.prisma.videoSession.findUnique({
      where: { roomName },
      include: {
        host: {
          select: { firstName: true, lastName: true },
        },
      },
    });

    return row ? this.mapToDomain(row) : null;
  }

  public async update(session: VideoSession): Promise<VideoSession> {
    const updated = await this.prisma.videoSession.update({
      where: { id: session.id },
      data: {
        title: session.title,
        description: session.description,
        subject: session.subject,
        startsAt: session.startsAt,
        endsAt: session.endsAt,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        status: session.status,
        joinOpensMinutesBefore: session.joinOpensMinutesBefore,
        chatEnabled: session.chatEnabled,
        cancelReason: session.cancelReason,
      },
      include: {
        host: {
          select: { firstName: true, lastName: true },
        },
      },
    });

    return this.mapToDomain(updated);
  }

  public async updateStatusAtomic(
    id: string,
    expectedStatus: VideoSessionStatus,
    newStatus: VideoSessionStatus,
    meta?: { startedAt?: Date; endedAt?: Date; cancelReason?: string },
  ): Promise<VideoSession | null> {
    const result = await this.prisma.videoSession.updateMany({
      where: {
        id,
        status: expectedStatus,
      },
      data: {
        status: newStatus,
        startedAt: meta?.startedAt,
        endedAt: meta?.endedAt,
        cancelReason: meta?.cancelReason,
      },
    });

    if (result.count === 0) {
      return null;
    }

    return this.findById(id);
  }

  public async findOverlappingForClass(
    classGroupId: string,
    startsAt: Date,
    endsAt: Date,
    excludeSessionId?: string,
  ): Promise<VideoSession[]> {
    const rows = await this.prisma.videoSession.findMany({
      where: {
        classGroupId,
        id: excludeSessionId ? { not: excludeSessionId } : undefined,
        status: { in: ['SCHEDULED', 'IN_PROGRESS'] },
        startsAt: { lt: endsAt },
        endsAt: { gt: startsAt },
      },
      include: {
        host: {
          select: { firstName: true, lastName: true },
        },
      },
    });

    return rows.map((r) => this.mapToDomain(r));
  }

  public async findActiveForHost(
    hostId: string,
    excludeSessionId?: string,
  ): Promise<VideoSession | null> {
    const row = await this.prisma.videoSession.findFirst({
      where: {
        hostId,
        id: excludeSessionId ? { not: excludeSessionId } : undefined,
        status: 'IN_PROGRESS',
      },
      include: {
        host: {
          select: { firstName: true, lastName: true },
        },
      },
    });

    return row ? this.mapToDomain(row) : null;
  }

  public async findUpcomingOrLiveForClass(
    classGroupId: string,
    now: Date,
  ): Promise<{ live: VideoSession | null; upcoming: VideoSession | null }> {
    return this.findUpcomingOrLiveForClasses([classGroupId], now, 24);
  }

  public async findUpcomingOrLiveForClasses(
    classGroupIds: string[],
    now: Date,
    horizonHours = 24,
  ): Promise<{ live: VideoSession | null; upcoming: VideoSession | null }> {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const classFilter: any =
      classGroupIds.length > 0 ? { classGroupId: { in: classGroupIds } } : {};

    // Auto-expire sessions that have already passed their scheduled end time
    try {
      await this.prisma.videoSession.updateMany({
        where: {
          ...classFilter,
          status: { in: ['IN_PROGRESS', 'SCHEDULED'] },
          endsAt: { lt: now },
        },
        data: {
          status: 'COMPLETED',
          endedAt: now,
        },
      });
    } catch {
      // Ignore background auto-completion error
    }

    const liveRow = await this.prisma.videoSession.findFirst({
      where: {
        ...classFilter,
        status: 'IN_PROGRESS',
        endsAt: { gt: now },
      },
      include: {
        host: {
          select: { firstName: true, lastName: true },
        },
      },
      orderBy: { startedAt: 'desc' },
    });

    const upcomingHorizon = new Date(now.getTime() + horizonHours * 60 * 60 * 1000);
    const upcomingRow = await this.prisma.videoSession.findFirst({
      where: {
        ...classFilter,
        status: 'SCHEDULED',
        startsAt: { lte: upcomingHorizon },
        endsAt: { gt: now },
      },
      include: {
        host: {
          select: { firstName: true, lastName: true },
        },
      },
      orderBy: { startsAt: 'asc' },
    });

    return {
      live: liveRow ? this.mapToDomain(liveRow) : null,
      upcoming: upcomingRow ? this.mapToDomain(upcomingRow) : null,
    };
  }

  public async list(
    filter: VideoSessionListFilter,
  ): Promise<{ items: VideoSession[]; total: number }> {
    const now = new Date();
    try {
      await this.prisma.videoSession.updateMany({
        where: {
          status: { in: ['IN_PROGRESS', 'SCHEDULED'] },
          endsAt: { lt: now },
        },
        data: {
          status: 'COMPLETED',
          endedAt: now,
        },
      });
    } catch {
      // Best-effort auto-completion of expired sessions
    }

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const where: any = {};

    if (filter.classGroupId) {
      where.classGroupId = filter.classGroupId;
    } else if (filter.classGroupIds && filter.classGroupIds.length > 0) {
      where.classGroupId = { in: filter.classGroupIds };
    }

    if (filter.hostId) {
      where.hostId = filter.hostId;
    }

    if (filter.status) {
      where.status = filter.status;
    }

    const [rows, total] = await Promise.all([
      this.prisma.videoSession.findMany({
        where,
        include: {
          host: {
            select: { firstName: true, lastName: true },
          },
        },
        orderBy: { startsAt: 'desc' },
        skip: filter.offset,
        take: filter.limit,
      }),
      this.prisma.videoSession.count({ where }),
    ]);

    return {
      items: rows.map((r) => this.mapToDomain(r)),
      total,
    };
  }
}
