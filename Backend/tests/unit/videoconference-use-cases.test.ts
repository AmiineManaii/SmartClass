import { describe, it, expect, beforeEach } from 'vitest';
import type {
  VideoSession,
  VideoSessionStatus,
  VideoSessionRepositoryPort,
  VideoSessionListFilter,
  ClassAccessPort,
  ClockPort,
} from '../../src/modules/videoconference/index.js';
import type { ClassAccessContext } from '../../src/modules/videoconference/domain/video-session-policy.js';
import { CreateVideoSessionUseCase } from '../../src/modules/videoconference/application/create-video-session.use-case.js';
import { ListVideoSessionsUseCase } from '../../src/modules/videoconference/application/list-video-sessions.use-case.js';
import { GetVideoSessionUseCase } from '../../src/modules/videoconference/application/get-video-session.use-case.js';
import { UpdateVideoSessionUseCase } from '../../src/modules/videoconference/application/update-video-session.use-case.js';
import { CancelVideoSessionUseCase } from '../../src/modules/videoconference/application/cancel-video-session.use-case.js';
import { InMemoryAuditService } from '../../src/shared/audit/audit.service.js';
import {
  ForbiddenError,
  ConflictError,
  NotFoundError,
  ValidationError,
} from '../../src/shared/errors/app-error.js';

class FakeVideoSessionRepository implements VideoSessionRepositoryPort {
  public sessions: VideoSession[] = [];

  public async create(session: VideoSession): Promise<VideoSession> {
    this.sessions.push({ ...session });
    return { ...session };
  }

  public async findById(id: string): Promise<VideoSession | null> {
    const s = this.sessions.find((item) => item.id === id);
    return s ? { ...s } : null;
  }

  public async findByRoomName(roomName: string): Promise<VideoSession | null> {
    const s = this.sessions.find((item) => item.roomName === roomName);
    return s ? { ...s } : null;
  }

  public async update(session: VideoSession): Promise<VideoSession> {
    const idx = this.sessions.findIndex((item) => item.id === session.id);
    if (idx === -1) throw new Error('Session not found in fake');
    this.sessions[idx] = { ...session };
    return { ...session };
  }

  public async updateStatusAtomic(
    id: string,
    expectedStatus: VideoSessionStatus,
    newStatus: VideoSessionStatus,
    meta?: { startedAt?: Date; endedAt?: Date; cancelReason?: string },
  ): Promise<VideoSession | null> {
    const s = this.sessions.find((item) => item.id === id);
    if (!s || s.status !== expectedStatus) {
      return null;
    }
    s.status = newStatus;
    if (meta?.startedAt) s.startedAt = meta.startedAt;
    if (meta?.endedAt) s.endedAt = meta.endedAt;
    if (meta?.cancelReason !== undefined) s.cancelReason = meta.cancelReason;
    s.updatedAt = new Date();
    return { ...s };
  }

  public async findOverlappingForClass(
    classGroupId: string,
    startsAt: Date,
    endsAt: Date,
    excludeSessionId?: string,
  ): Promise<VideoSession[]> {
    return this.sessions.filter((s) => {
      if (s.classGroupId !== classGroupId) return false;
      if (excludeSessionId && s.id === excludeSessionId) return false;
      if (s.status !== 'SCHEDULED' && s.status !== 'IN_PROGRESS') return false;
      return s.startsAt.getTime() < endsAt.getTime() && s.endsAt.getTime() > startsAt.getTime();
    });
  }

  public async findActiveForHost(
    hostId: string,
    excludeSessionId?: string,
  ): Promise<VideoSession | null> {
    const found = this.sessions.find((s) => {
      if (s.hostId !== hostId) return false;
      if (excludeSessionId && s.id === excludeSessionId) return false;
      return s.status === 'IN_PROGRESS';
    });
    return found ? { ...found } : null;
  }

  public async findUpcomingOrLiveForClass(
    classGroupId: string,
    now: Date,
  ): Promise<{ live: VideoSession | null; upcoming: VideoSession | null }> {
    const live =
      this.sessions.find((s) => s.classGroupId === classGroupId && s.status === 'IN_PROGRESS') ??
      null;
    const upcoming =
      this.sessions
        .filter(
          (s) =>
            s.classGroupId === classGroupId &&
            s.status === 'SCHEDULED' &&
            s.startsAt.getTime() >= now.getTime(),
        )
        .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime())[0] ?? null;
    return { live, upcoming };
  }

  public async findUpcomingOrLiveForClasses(
    classGroupIds: string[],
    now: Date,
    horizonHours = 24,
  ): Promise<{ live: VideoSession | null; upcoming: VideoSession | null }> {
    const live =
      this.sessions.find(
        (s) =>
          (classGroupIds.length === 0 || classGroupIds.includes(s.classGroupId)) &&
          s.status === 'IN_PROGRESS',
      ) ?? null;

    const horizon = new Date(now.getTime() + horizonHours * 60 * 60 * 1000);
    const upcoming =
      this.sessions
        .filter(
          (s) =>
            (classGroupIds.length === 0 || classGroupIds.includes(s.classGroupId)) &&
            s.status === 'SCHEDULED' &&
            s.startsAt.getTime() >= now.getTime() &&
            s.startsAt.getTime() <= horizon.getTime(),
        )
        .sort((a, b) => a.startsAt.getTime() - b.startsAt.getTime())[0] ?? null;

    return { live, upcoming };
  }

  public async list(
    filter: VideoSessionListFilter,
  ): Promise<{ items: VideoSession[]; total: number }> {
    let filtered = [...this.sessions];

    if (filter.classGroupId) {
      filtered = filtered.filter((s) => s.classGroupId === filter.classGroupId);
    } else if (filter.classGroupIds && filter.classGroupIds.length > 0) {
      filtered = filtered.filter((s) => filter.classGroupIds!.includes(s.classGroupId));
    }

    if (filter.hostId) {
      filtered = filtered.filter((s) => s.hostId === filter.hostId);
    }

    if (filter.status) {
      filtered = filtered.filter((s) => s.status === filter.status);
    }

    const total = filtered.length;
    const items = filtered.slice(filter.offset, filter.offset + filter.limit);
    return { items, total };
  }
}

class FakeClassAccessAdapter implements ClassAccessPort {
  public accessMap = new Map<string, ClassAccessContext>();
  public userClassesMap = new Map<string, string[]>();

  public async getClassAccess(userId: string, classGroupId: string): Promise<ClassAccessContext> {
    return (
      this.accessMap.get(`${userId}:${classGroupId}`) ?? {
        isMember: false,
        isTeacherAssigned: false,
        isReferent: false,
        isApprovedTeacher: false,
      }
    );
  }

  public async getUserClassGroupIds(userId: string): Promise<string[]> {
    return this.userClassesMap.get(userId) ?? [];
  }

  public async getClassMemberUserIds(_classGroupId: string): Promise<string[]> {
    return [];
  }
}

class FakeClock implements ClockPort {
  constructor(private currentTime = new Date('2026-10-25T14:00:00.000Z')) {}
  public now(): Date {
    return new Date(this.currentTime);
  }
  public set(date: Date): void {
    this.currentTime = new Date(date);
  }
}

describe('Videoconference Use Cases (Phase 2)', () => {
  let repo: FakeVideoSessionRepository;
  let classAccess: FakeClassAccessAdapter;
  let clock: FakeClock;
  let audit: InMemoryAuditService;

  const teacherUser = { id: 'teacher-1', role: 'TEACHER' as const };
  const studentUser = { id: 'student-1', role: 'STUDENT' as const };
  const adminUser = { id: 'admin-1', role: 'ADMIN' as const };
  const classId = 'class-123';

  beforeEach(() => {
    repo = new FakeVideoSessionRepository();
    classAccess = new FakeClassAccessAdapter();
    clock = new FakeClock();
    audit = new InMemoryAuditService();

    // Teacher has access to classId
    classAccess.accessMap.set(`teacher-1:${classId}`, {
      isMember: false,
      isTeacherAssigned: true,
      isReferent: false,
      isApprovedTeacher: true,
    });
    classAccess.userClassesMap.set('teacher-1', [classId]);

    // Student is member of classId
    classAccess.accessMap.set(`student-1:${classId}`, {
      isMember: true,
      isTeacherAssigned: false,
      isReferent: false,
      isApprovedTeacher: false,
    });
    classAccess.userClassesMap.set('student-1', [classId]);
  });

  describe('CreateVideoSessionUseCase', () => {
    it('creates an immediate live session (mode=NOW) with IN_PROGRESS status', async () => {
      const useCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);

      const result = await useCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'Algèbre Linéaire - Cours 1',
        mode: 'NOW',
        durationMinutes: 60,
      });

      expect(result.id).toBeDefined();
      expect(result.title).toBe('Algèbre Linéaire - Cours 1');
      expect(result.status).toBe('IN_PROGRESS');
      expect(result.startedAt).toBe('2026-10-25T14:00:00.000Z');
      expect(result.startsAt).toBe('2026-10-25T14:00:00.000Z');
      expect(result.endsAt).toBe('2026-10-25T15:00:00.000Z');

      expect(repo.sessions).toHaveLength(1);
      expect(repo.sessions[0]?.roomName).toMatch(/^room-/);
      expect(audit.logs).toHaveLength(1);
      expect(audit.logs[0]?.action).toBe('session.created');
    });

    it('creates a scheduled session (mode=SCHEDULED) with startsAt in future', async () => {
      const useCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);

      const result = await useCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'Séance de révision',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T09:00:00.000Z',
        durationMinutes: 90,
        joinOpensMinutesBefore: 10,
      });

      expect(result.status).toBe('SCHEDULED');
      expect(result.startedAt).toBeNull();
      expect(result.startsAt).toBe('2026-10-26T09:00:00.000Z');
      expect(result.endsAt).toBe('2026-10-26T10:30:00.000Z');
      expect(result.joinOpensMinutesBefore).toBe(10);
    });

    it('denies creation if user is a student', async () => {
      const useCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);

      await expect(
        useCase.execute(studentUser, {
          classGroupId: classId,
          title: 'Student Attempt',
          mode: 'NOW',
        }),
      ).rejects.toThrow(ForbiddenError);
    });

    it('rejects immediate session if host already has an active session in progress', async () => {
      const useCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);

      await useCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'First Active Live',
        mode: 'NOW',
      });

      await expect(
        useCase.execute(teacherUser, {
          classGroupId: classId,
          title: 'Second Active Live Attempt',
          mode: 'NOW',
        }),
      ).rejects.toThrow(ConflictError);
    });

    it('rejects scheduled session if start time is in the past', async () => {
      const useCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);

      await expect(
        useCase.execute(teacherUser, {
          classGroupId: classId,
          title: 'Past Session',
          mode: 'SCHEDULED',
          startsAt: '2026-10-25T10:00:00.000Z', // 4 hours in past
        }),
      ).rejects.toThrow(ValidationError);
    });

    it('rejects session if another session overlaps for the class', async () => {
      const useCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);

      await useCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'First Scheduled',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T10:00:00.000Z',
        durationMinutes: 60,
      });

      // Overlaps 10:30 to 11:30
      await expect(
        useCase.execute(teacherUser, {
          classGroupId: classId,
          title: 'Overlapping Session',
          mode: 'SCHEDULED',
          startsAt: '2026-10-26T10:30:00.000Z',
          durationMinutes: 60,
        }),
      ).rejects.toThrow(ConflictError);
    });
  });

  describe('ListVideoSessionsUseCase', () => {
    beforeEach(async () => {
      const createUseCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);
      await createUseCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'Session 1',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T08:00:00.000Z',
      });
      await createUseCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'Session 2',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T10:00:00.000Z',
      });
    });

    it('returns paginated items for student enrolled in class', async () => {
      const useCase = new ListVideoSessionsUseCase(repo, classAccess);
      const result = await useCase.execute(studentUser, { classGroupId: classId });

      expect(result.items).toHaveLength(2);
      expect(result.meta.total).toBe(2);
      expect(result.meta.page).toBe(1);
    });

    it('denies student access to un-enrolled class', async () => {
      const useCase = new ListVideoSessionsUseCase(repo, classAccess);
      await expect(
        useCase.execute(studentUser, { classGroupId: 'unauthorized-class' }),
      ).rejects.toThrow(ForbiddenError);
    });

    it('filters sessions by scope=mine for teacher', async () => {
      const useCase = new ListVideoSessionsUseCase(repo, classAccess);
      const result = await useCase.execute(teacherUser, { scope: 'mine' });

      expect(result.items).toHaveLength(2);
      expect(result.items.every((s) => s.hostId === teacherUser.id)).toBe(true);
    });

    it('allows admin to list all sessions without restriction', async () => {
      const useCase = new ListVideoSessionsUseCase(repo, classAccess);
      const result = await useCase.execute(adminUser, {});

      expect(result.items).toHaveLength(2);
      expect(result.meta.total).toBe(2);
    });
  });

  describe('GetVideoSessionUseCase', () => {
    it('returns session details for member of class', async () => {
      const createUseCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);
      const created = await createUseCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'Session Details',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T10:00:00.000Z',
      });

      const getUseCase = new GetVideoSessionUseCase(repo, classAccess);
      const found = await getUseCase.execute(studentUser, created.id);

      expect(found.id).toBe(created.id);
      expect(found.title).toBe('Session Details');
    });

    it('throws NotFoundError for unknown id', async () => {
      const getUseCase = new GetVideoSessionUseCase(repo, classAccess);
      await expect(getUseCase.execute(studentUser, 'unknown-id')).rejects.toThrow(NotFoundError);
    });
  });

  describe('UpdateVideoSessionUseCase', () => {
    it('updates title and duration of scheduled session', async () => {
      const createUseCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);
      const created = await createUseCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'Original Title',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T10:00:00.000Z',
        durationMinutes: 60,
      });

      const updateUseCase = new UpdateVideoSessionUseCase(repo, classAccess, clock, audit);
      const updated = await updateUseCase.execute(teacherUser, created.id, {
        title: 'Updated Title',
        durationMinutes: 90,
      });

      expect(updated.title).toBe('Updated Title');
      expect(updated.endsAt).toBe('2026-10-26T11:30:00.000Z');
      expect(audit.logs.some((l) => l.action === 'session.updated')).toBe(true);
    });

    it('denies update if user is not host or admin', async () => {
      const createUseCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);
      const created = await createUseCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'Original Title',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T10:00:00.000Z',
      });

      const updateUseCase = new UpdateVideoSessionUseCase(repo, classAccess, clock, audit);
      await expect(
        updateUseCase.execute(studentUser, created.id, { title: 'Hacked Title' }),
      ).rejects.toThrow(ForbiddenError);
    });

    it('rejects update if session is already IN_PROGRESS', async () => {
      const createUseCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);
      const created = await createUseCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'Live Now',
        mode: 'NOW',
      });

      const updateUseCase = new UpdateVideoSessionUseCase(repo, classAccess, clock, audit);
      await expect(
        updateUseCase.execute(teacherUser, created.id, { title: 'New Title' }),
      ).rejects.toThrow(ConflictError);
    });
  });

  describe('CancelVideoSessionUseCase', () => {
    it('cancels scheduled session and records cancelReason and audit log', async () => {
      const createUseCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);
      const created = await createUseCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'To Cancel',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T10:00:00.000Z',
      });

      const cancelUseCase = new CancelVideoSessionUseCase(repo, classAccess, audit);
      const canceled = await cancelUseCase.execute(teacherUser, created.id, {
        reason: 'Professeur malade',
      });

      expect(canceled.status).toBe('CANCELED');
      expect(canceled.cancelReason).toBe('Professeur malade');

      const found = await repo.findById(created.id);
      expect(found?.status).toBe('CANCELED');
      expect(audit.logs.some((l) => l.action === 'session.canceled')).toBe(true);
    });

    it('denies cancellation by unauthorized student', async () => {
      const createUseCase = new CreateVideoSessionUseCase(repo, classAccess, clock, audit);
      const created = await createUseCase.execute(teacherUser, {
        classGroupId: classId,
        title: 'To Cancel',
        mode: 'SCHEDULED',
        startsAt: '2026-10-26T10:00:00.000Z',
      });

      const cancelUseCase = new CancelVideoSessionUseCase(repo, classAccess, audit);
      await expect(cancelUseCase.execute(studentUser, created.id, {})).rejects.toThrow(
        ForbiddenError,
      );
    });
  });
});
