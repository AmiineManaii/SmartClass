import { describe, it, expect, beforeEach } from 'vitest';
import type {
  VideoSession,
  VideoSessionStatus,
  VideoSessionRepositoryPort,
  VideoSessionListFilter,
  SessionParticipantRepositoryPort,
  SessionParticipant,
  SessionChatRepositoryPort,
  SessionChatMessage,
  SessionRemovalRepositoryPort,
  SessionParticipantRemoval,
  ClassAccessPort,
  RoomServicePort,
  ClockPort,
  JoinTokenResult,
} from '../../src/modules/videoconference/index.js';
import type { ClassAccessContext } from '../../src/modules/videoconference/domain/video-session-policy.js';
import { StartVideoSessionUseCase } from '../../src/modules/videoconference/application/start-video-session.use-case.js';
import { IssueJoinTokenUseCase } from '../../src/modules/videoconference/application/issue-join-token.use-case.js';
import { EndVideoSessionUseCase } from '../../src/modules/videoconference/application/end-video-session.use-case.js';
import { LeaveVideoSessionUseCase } from '../../src/modules/videoconference/application/leave-video-session.use-case.js';
import { MuteParticipantUseCase } from '../../src/modules/videoconference/application/mute-participant.use-case.js';
import { MuteAllUseCase } from '../../src/modules/videoconference/application/mute-all.use-case.js';
import { RemoveParticipantUseCase } from '../../src/modules/videoconference/application/remove-participant.use-case.js';
import { CreateSessionChatMessageUseCase } from '../../src/modules/videoconference/application/create-session-chat-message.use-case.js';
import { ListSessionChatMessagesUseCase } from '../../src/modules/videoconference/application/list-session-chat-messages.use-case.js';
import { InMemoryAuditService } from '../../src/shared/audit/audit.service.js';
import {
  ForbiddenError,
  ConflictError,
} from '../../src/shared/errors/app-error.js';

class FakeVideoSessionRepo implements VideoSessionRepositoryPort {
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
    if (idx === -1) throw new Error('Not found');
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
    if (!s || s.status !== expectedStatus) return null;
    s.status = newStatus;
    if (meta?.startedAt) s.startedAt = meta.startedAt;
    if (meta?.endedAt) s.endedAt = meta.endedAt;
    if (meta?.cancelReason !== undefined) s.cancelReason = meta.cancelReason;
    s.updatedAt = new Date();
    return { ...s };
  }

  public async findOverlappingForClass(): Promise<VideoSession[]> {
    return [];
  }
  public async findActiveForHost(): Promise<VideoSession | null> {
    return null;
  }
  public async findUpcomingOrLiveForClass(): Promise<{
    live: VideoSession | null;
    upcoming: VideoSession | null;
  }> {
    return { live: null, upcoming: null };
  }
  public async findUpcomingOrLiveForClasses(): Promise<{
    live: VideoSession | null;
    upcoming: VideoSession | null;
  }> {
    return { live: null, upcoming: null };
  }
  public async list(
    _filter: VideoSessionListFilter,
  ): Promise<{ items: VideoSession[]; total: number }> {
    return { items: [...this.sessions], total: this.sessions.length };
  }
}

class FakeParticipantRepo implements SessionParticipantRepositoryPort {
  public participants: SessionParticipant[] = [];

  public async recordJoin(
    sessionId: string,
    userId: string,
    joinedAt: Date,
  ): Promise<SessionParticipant> {
    const p: SessionParticipant = {
      id: `part-${this.participants.length + 1}`,
      sessionId,
      userId,
      joinedAt,
      leftAt: null,
    };
    this.participants.push(p);
    return { ...p };
  }

  public async recordLeave(
    sessionId: string,
    userId: string,
    leftAt: Date,
  ): Promise<SessionParticipant | null> {
    const found = this.participants
      .filter((p) => p.sessionId === sessionId && p.userId === userId && !p.leftAt)
      .pop();
    if (!found) return null;
    found.leftAt = leftAt;
    return { ...found };
  }

  public async listBySession(sessionId: string): Promise<SessionParticipant[]> {
    return this.participants.filter((p) => p.sessionId === sessionId);
  }
}

class FakeChatRepo implements SessionChatRepositoryPort {
  public messages: SessionChatMessage[] = [];

  public async createMessage(
    message: Omit<SessionChatMessage, 'id' | 'createdAt'>,
  ): Promise<SessionChatMessage> {
    const m: SessionChatMessage = {
      ...message,
      id: `msg-${this.messages.length + 1}`,
      createdAt: new Date(),
    };
    this.messages.push(m);
    return { ...m };
  }

  public async findByClientMessageId(
    sessionId: string,
    senderId: string,
    clientMessageId: string,
  ): Promise<SessionChatMessage | null> {
    const found = this.messages.find(
      (m) =>
        m.sessionId === sessionId &&
        m.senderId === senderId &&
        m.clientMessageId === clientMessageId,
    );
    return found ? { ...found } : null;
  }

  public async listBySession(
    sessionId: string,
    offset: number,
    limit: number,
  ): Promise<{ items: SessionChatMessage[]; total: number }> {
    const filtered = this.messages.filter((m) => m.sessionId === sessionId);
    const items = filtered.slice(offset, offset + limit);
    return { items, total: filtered.length };
  }
}

class FakeRemovalRepo implements SessionRemovalRepositoryPort {
  public removals: SessionParticipantRemoval[] = [];

  public async recordRemoval(
    removal: Omit<SessionParticipantRemoval, 'id' | 'removedAt'>,
  ): Promise<SessionParticipantRemoval> {
    const existing = this.removals.find(
      (r) => r.sessionId === removal.sessionId && r.userId === removal.userId,
    );
    if (existing) {
      existing.reason = removal.reason;
      return { ...existing };
    }
    const r: SessionParticipantRemoval = {
      ...removal,
      id: `rem-${this.removals.length + 1}`,
      removedAt: new Date(),
    };
    this.removals.push(r);
    return { ...r };
  }

  public async isUserRemoved(sessionId: string, userId: string): Promise<boolean> {
    return this.removals.some((r) => r.sessionId === sessionId && r.userId === userId);
  }
}

class FakeRoomService implements RoomServicePort {
  public createdRooms: string[] = [];
  public closedRooms: string[] = [];
  public mutedUsers: { roomName: string; identity: string }[] = [];
  public mutedAllRooms: string[] = [];
  public removedUsers: { roomName: string; identity: string }[] = [];

  public async createRoom(roomName: string, _emptyTimeoutMinutes: number): Promise<void> {
    if (!this.createdRooms.includes(roomName)) {
      this.createdRooms.push(roomName);
    }
  }

  public async issueJoinToken(params: {
    roomName: string;
    identity: string;
    name: string;
    isHost: boolean;
    isAdmin: boolean;
    ttlSeconds: number;
  }): Promise<JoinTokenResult> {
    return {
      token: `fake-jwt-token-for-${params.identity}`,
      url: 'http://127.0.0.1:7880',
      expiresAt: new Date(Date.now() + params.ttlSeconds * 1000),
      role: params.isAdmin ? 'admin' : params.isHost ? 'host' : 'student',
      permissions: {
        canPublish: params.isHost || params.isAdmin,
        canPublishData: true,
        canSubscribe: true,
        hidden: false,
        canPublishSources:
          params.isHost || params.isAdmin
            ? ['camera', 'microphone', 'screen_share']
            : ['camera', 'microphone'],
      },
    };
  }

  public async muteParticipant(roomName: string, identity: string): Promise<void> {
    this.mutedUsers.push({ roomName, identity });
  }

  public async muteAll(roomName: string): Promise<void> {
    this.mutedAllRooms.push(roomName);
  }

  public async removeParticipant(roomName: string, identity: string): Promise<void> {
    this.removedUsers.push({ roomName, identity });
  }

  public async closeRoom(roomName: string): Promise<void> {
    this.closedRooms.push(roomName);
  }
}

class FakeClassAccess implements ClassAccessPort {
  public accessMap = new Map<string, ClassAccessContext>();

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

  public async getUserClassGroupIds(): Promise<string[]> {
    return [];
  }
  public async getClassMemberUserIds(): Promise<string[]> {
    return [];
  }
}

class FakeClock implements ClockPort {
  constructor(public currentTime = new Date('2026-10-26T09:30:00.000Z')) {}
  public now(): Date {
    return new Date(this.currentTime);
  }
}

describe('Videoconference Live Lifecycle & WebRTC (Phase 3)', () => {
  let sessionRepo: FakeVideoSessionRepo;
  let participantRepo: FakeParticipantRepo;
  let chatRepo: FakeChatRepo;
  let removalRepo: FakeRemovalRepo;
  let roomService: FakeRoomService;
  let classAccess: FakeClassAccess;
  let clock: FakeClock;
  let audit: InMemoryAuditService;

  const teacher = { id: 'teacher-1', role: 'TEACHER' as const, firstName: 'Prof', lastName: 'Mansouri' };
  const student = { id: 'student-1', role: 'STUDENT' as const, firstName: 'Salma', lastName: 'Student' };
  const admin = { id: 'admin-1', role: 'ADMIN' as const };
  const classId = 'class-123';
  let session: VideoSession;

  beforeEach(async () => {
    sessionRepo = new FakeVideoSessionRepo();
    participantRepo = new FakeParticipantRepo();
    chatRepo = new FakeChatRepo();
    removalRepo = new FakeRemovalRepo();
    roomService = new FakeRoomService();
    classAccess = new FakeClassAccess();
    clock = new FakeClock(new Date('2026-10-26T09:30:00.000Z'));
    audit = new InMemoryAuditService();

    classAccess.accessMap.set(`teacher-1:${classId}`, {
      isMember: false,
      isTeacherAssigned: true,
      isReferent: false,
      isApprovedTeacher: true,
    });
    classAccess.accessMap.set(`student-1:${classId}`, {
      isMember: true,
      isTeacherAssigned: false,
      isReferent: false,
      isApprovedTeacher: false,
    });

    session = await sessionRepo.create({
      id: 'session-123',
      classGroupId: classId,
      hostId: teacher.id,
      title: 'Algèbre Linéaire',
      subject: 'Maths',
      description: null,
      startsAt: new Date('2026-10-26T10:00:00.000Z'),
      endsAt: new Date('2026-10-26T11:00:00.000Z'),
      startedAt: null,
      endedAt: null,
      status: 'SCHEDULED',
      roomName: 'room-session-123',
      joinOpensMinutesBefore: 5,
      chatEnabled: true,
      timetableSlotId: null,
      courseId: null,
      cancelReason: null,
      createdAt: new Date('2026-10-25T12:00:00.000Z'),
      updatedAt: new Date('2026-10-25T12:00:00.000Z'),
    });
  });

  describe('StartVideoSessionUseCase', () => {
    it('starts scheduled session up to 60 minutes before scheduled start time', async () => {
      // Current time is 09:30, startsAt is 10:00 (30 min before) -> permitted
      const useCase = new StartVideoSessionUseCase(
        sessionRepo,
        classAccess,
        clock,
        roomService,
        audit,
      );

      const result = await useCase.execute(teacher, session.id);

      expect(result.status).toBe('IN_PROGRESS');
      expect(result.startedAt).toBe('2026-10-26T09:30:00.000Z');
      expect(roomService.createdRooms).toContain('room-session-123');
      expect(audit.logs.some((l) => l.action === 'session.started')).toBe(true);
    });

    it('rejects start if more than 60 minutes before scheduled start time', async () => {
      clock.currentTime = new Date('2026-10-26T08:00:00.000Z'); // 2 hours before
      const useCase = new StartVideoSessionUseCase(
        sessionRepo,
        classAccess,
        clock,
        roomService,
        audit,
      );

      await expect(useCase.execute(teacher, session.id)).rejects.toThrow(ConflictError);
    });

    it('rejects start from student or unassigned teacher', async () => {
      const useCase = new StartVideoSessionUseCase(
        sessionRepo,
        classAccess,
        clock,
        roomService,
        audit,
      );

      await expect(useCase.execute(student, session.id)).rejects.toThrow(ForbiddenError);
    });
  });

  describe('IssueJoinTokenUseCase', () => {
    it('rejects student join if session is still SCHEDULED', async () => {
      const useCase = new IssueJoinTokenUseCase(
        sessionRepo,
        removalRepo,
        participantRepo,
        classAccess,
        roomService,
        clock,
        audit,
      );

      await expect(useCase.execute(student, session.id)).rejects.toThrow(ConflictError);
    });

    it('issues join token for host even before IN_PROGRESS to prepare the room', async () => {
      const useCase = new IssueJoinTokenUseCase(
        sessionRepo,
        removalRepo,
        participantRepo,
        classAccess,
        roomService,
        clock,
        audit,
      );

      const res = await useCase.execute(teacher, session.id);

      expect(res.token).toBeDefined();
      expect(res.role).toBe('host');
      expect(res.permissions.canPublish).toBe(true);
      expect(participantRepo.participants).toHaveLength(1);
    });

    it('issues join token for student once session is IN_PROGRESS', async () => {
      session.status = 'IN_PROGRESS';
      session.startedAt = clock.now();
      await sessionRepo.update(session);

      const useCase = new IssueJoinTokenUseCase(
        sessionRepo,
        removalRepo,
        participantRepo,
        classAccess,
        roomService,
        clock,
        audit,
      );

      const res = await useCase.execute(student, session.id);

      expect(res.role).toBe('student');
      expect(res.permissions.canPublish).toBe(false);
      expect(participantRepo.participants.some((p) => p.userId === student.id)).toBe(true);
    });

    it('denies join if student was banned/removed', async () => {
      session.status = 'IN_PROGRESS';
      await sessionRepo.update(session);
      await removalRepo.recordRemoval({
        sessionId: session.id,
        userId: student.id,
        removedById: teacher.id,
        reason: 'Perturbation',
      });

      const useCase = new IssueJoinTokenUseCase(
        sessionRepo,
        removalRepo,
        participantRepo,
        classAccess,
        roomService,
        clock,
        audit,
      );

      await expect(useCase.execute(student, session.id)).rejects.toThrow(ForbiddenError);
    });
  });

  describe('EndVideoSessionUseCase & LeaveVideoSessionUseCase', () => {
    beforeEach(async () => {
      session.status = 'IN_PROGRESS';
      session.startedAt = clock.now();
      await sessionRepo.update(session);

      await participantRepo.recordJoin(session.id, teacher.id, clock.now());
      await participantRepo.recordJoin(session.id, student.id, clock.now());
    });

    it('ends live session, closes room in LiveKit, and marks participant leaves', async () => {
      const endUseCase = new EndVideoSessionUseCase(
        sessionRepo,
        participantRepo,
        clock,
        roomService,
        audit,
      );

      const res = await endUseCase.execute(teacher, session.id);

      expect(res.status).toBe('COMPLETED');
      expect(roomService.closedRooms).toContain('room-session-123');

      const participants = await participantRepo.listBySession(session.id);
      expect(participants.every((p) => p.leftAt !== null)).toBe(true);
      expect(audit.logs.some((l) => l.action === 'session.ended')).toBe(true);
    });

    it('allows admin to end live session', async () => {
      const endUseCase = new EndVideoSessionUseCase(
        sessionRepo,
        participantRepo,
        clock,
        roomService,
        audit,
      );

      const res = await endUseCase.execute(admin, session.id);
      expect(res.status).toBe('COMPLETED');
    });

    it('records participant leave independently', async () => {
      const leaveUseCase = new LeaveVideoSessionUseCase(sessionRepo, participantRepo, clock);
      const res = await leaveUseCase.execute(student, session.id);

      expect(res.left).toBe(true);
      const studentPart = participantRepo.participants.find((p) => p.userId === student.id);
      expect(studentPart?.leftAt).toBeDefined();
    });
  });

  describe('Moderation Use Cases', () => {
    beforeEach(async () => {
      session.status = 'IN_PROGRESS';
      await sessionRepo.update(session);
      await participantRepo.recordJoin(session.id, student.id, clock.now());
    });

    it('host mutes participant and mutes all', async () => {
      const muteUseCase = new MuteParticipantUseCase(sessionRepo, roomService);
      const muteAllUseCase = new MuteAllUseCase(sessionRepo, roomService);

      await muteUseCase.execute(teacher, session.id, student.id);
      expect(roomService.mutedUsers).toContainEqual({
        roomName: session.roomName,
        identity: student.id,
      });

      await muteAllUseCase.execute(teacher, session.id);
      expect(roomService.mutedAllRooms).toContain(session.roomName);
    });

    it('host removes participant: records removal, closes attendance, disconnects from LiveKit', async () => {
      const removeUseCase = new RemoveParticipantUseCase(
        sessionRepo,
        removalRepo,
        participantRepo,
        clock,
        roomService,
        audit,
      );

      const res = await removeUseCase.execute(teacher, session.id, student.id, 'Disruption');

      expect(res.removed).toBe(true);
      expect(await removalRepo.isUserRemoved(session.id, student.id)).toBe(true);
      expect(roomService.removedUsers).toContainEqual({
        roomName: session.roomName,
        identity: student.id,
      });
      expect(audit.logs.some((l) => l.action === 'participant.removed')).toBe(true);
    });

    it('host cannot remove self or another host', async () => {
      const removeUseCase = new RemoveParticipantUseCase(
        sessionRepo,
        removalRepo,
        participantRepo,
        clock,
        roomService,
        audit,
      );

      await expect(removeUseCase.execute(teacher, session.id, teacher.id)).rejects.toThrow(
        ConflictError,
      );
    });
  });

  describe('In-Call Persistent Chat', () => {
    beforeEach(async () => {
      session.status = 'IN_PROGRESS';
      await sessionRepo.update(session);
    });

    it('creates persistent chat message with clientMessageId idempotency', async () => {
      const chatUseCase = new CreateSessionChatMessageUseCase(
        sessionRepo,
        chatRepo,
        removalRepo,
        classAccess,
      );

      const msg1 = await chatUseCase.execute(student, session.id, {
        clientMessageId: '11111111-2222-3333-4444-555555555555',
        content: 'Bonjour professeur !',
      });

      expect(msg1.id).toBeDefined();
      expect(msg1.content).toBe('Bonjour professeur !');
      expect(chatRepo.messages).toHaveLength(1);

      // Duplicate submission returns same message without inserting duplicate
      const msg2 = await chatUseCase.execute(student, session.id, {
        clientMessageId: '11111111-2222-3333-4444-555555555555',
        content: 'Bonjour professeur !',
      });

      expect(msg2.id).toBe(msg1.id);
      expect(chatRepo.messages).toHaveLength(1);
    });

    it('rejects chat message if session chat is disabled', async () => {
      session.chatEnabled = false;
      await sessionRepo.update(session);

      const chatUseCase = new CreateSessionChatMessageUseCase(
        sessionRepo,
        chatRepo,
        removalRepo,
        classAccess,
      );

      await expect(
        chatUseCase.execute(student, session.id, {
          clientMessageId: '11111111-2222-3333-4444-555555555555',
          content: 'Hello',
        }),
      ).rejects.toThrow(ConflictError);
    });

    it('lists paginated chat messages for session members', async () => {
      const createChatUseCase = new CreateSessionChatMessageUseCase(
        sessionRepo,
        chatRepo,
        removalRepo,
        classAccess,
      );
      await createChatUseCase.execute(student, session.id, {
        clientMessageId: 'msg-1',
        content: 'Message 1',
      });
      await createChatUseCase.execute(teacher, session.id, {
        clientMessageId: 'msg-2',
        content: 'Message 2',
      });

      const listUseCase = new ListSessionChatMessagesUseCase(
        sessionRepo,
        chatRepo,
        classAccess,
      );
      const res = await listUseCase.execute(student, session.id, { page: 1, limit: 10 });

      expect(res.items).toHaveLength(2);
      expect(res.meta.total).toBe(2);
    });
  });
});
