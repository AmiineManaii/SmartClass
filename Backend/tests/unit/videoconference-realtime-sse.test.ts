import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import type { Request, Response } from 'express';
import { InMemoryLiveEventsHub } from '../../src/modules/videoconference/infrastructure/in-memory-live-events.hub.js';
import { GetMyNextSessionUseCase } from '../../src/modules/videoconference/application/get-my-next-session.use-case.js';
import type { ClassAccessPort } from '../../src/modules/videoconference/domain/class-access.port.js';
import type { VideoSessionRepositoryPort } from '../../src/modules/videoconference/domain/video-session-repository.port.js';
import type { ClockPort } from '../../src/modules/videoconference/domain/clock.port.js';
import type { VideoSession } from '../../src/modules/videoconference/domain/video-session.entity.js';

interface MockResponse {
  writeHead: ReturnType<typeof vi.fn>;
  write: ReturnType<typeof vi.fn>;
  end: ReturnType<typeof vi.fn>;
  on: ReturnType<typeof vi.fn>;
  emit: (event: string) => void;
  written: string[];
  headers: Record<string, unknown>;
  writableEnded: boolean;
}

const createMockResponse = (): Response & MockResponse => {
  const written: string[] = [];
  const headers: Record<string, unknown> = {};
  const listeners: Record<string, (() => void)[]> = {};

  const mock = {
    writeHead: vi.fn((_status: number, hdrs: Record<string, unknown>) => {
      Object.assign(headers, hdrs);
    }),
    write: vi.fn((data: string) => {
      written.push(data);
      return true;
    }),
    end: vi.fn(function (this: MockResponse) {
      this.writableEnded = true;
    }),
    on: vi.fn((event: string, cb: () => void) => {
      listeners[event] = listeners[event] || [];
      listeners[event].push(cb);
    }),
    emit: (event: string) => {
      listeners[event]?.forEach((cb) => cb());
    },
    written,
    headers,
    writableEnded: false,
  };

  return mock as unknown as Response & MockResponse;
};

const createMockRequest = () => {
  const listeners: Record<string, (() => void)[]> = {};
  return {
    on: vi.fn((event: string, cb: () => void) => {
      listeners[event] = listeners[event] || [];
      listeners[event].push(cb);
    }),
    emit: (event: string) => {
      listeners[event]?.forEach((cb) => cb());
    },
  } as unknown as Request & { emit: (event: string) => void };
};

describe('InMemoryLiveEventsHub', () => {
  let hub: InMemoryLiveEventsHub;
  let mockClassAccess: ClassAccessPort;

  beforeEach(() => {
    vi.useFakeTimers();
    mockClassAccess = {
      getClassAccess: vi.fn(),
      getUserClassGroupIds: vi.fn().mockResolvedValue(['class-1']),
      getClassMemberUserIds: vi.fn().mockResolvedValue(['user-1', 'user-2']),
    };
    hub = new InMemoryLiveEventsHub(mockClassAccess);
  });

  afterEach(() => {
    hub.destroy();
    vi.useRealTimers();
  });

  it('subscribes user and sends initial SSE headers and connected ping', () => {
    const res = createMockResponse();
    const req = createMockRequest();

    const cleanup = hub.subscribe('user-1', res, req);

    expect(res.writeHead).toHaveBeenCalledWith(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache, no-store',
      Connection: 'keep-alive',
      'X-Accel-Buffering': 'no',
    });
    expect(res.written).toContain(': connected\n\n');
    expect(hub.getActiveConnectionCount()).toBe(1);
    expect(hub.getUserConnectionCount('user-1')).toBe(1);

    cleanup();
    expect(hub.getActiveConnectionCount()).toBe(0);
  });

  it('periodically emits heartbeat ping every 10 seconds', () => {
    const res = createMockResponse();
    const req = createMockRequest();

    hub.subscribe('user-1', res, req);
    expect(res.written).toEqual([': connected\n\n']);

    vi.advanceTimersByTime(10_000);
    expect(res.written).toContain(': ping\n\n');

    vi.advanceTimersByTime(10_000);
    expect(res.written.filter((w) => w === ': ping\n\n').length).toBe(2);
  });

  it('limits max connections per user to 3 by closing the oldest connection', () => {
    const res1 = createMockResponse();
    const req1 = createMockRequest();
    const res2 = createMockResponse();
    const req2 = createMockRequest();
    const res3 = createMockResponse();
    const req3 = createMockRequest();
    const res4 = createMockResponse();
    const req4 = createMockRequest();

    hub.subscribe('user-1', res1, req1);
    vi.advanceTimersByTime(10);
    hub.subscribe('user-1', res2, req2);
    vi.advanceTimersByTime(10);
    hub.subscribe('user-1', res3, req3);

    expect(hub.getUserConnectionCount('user-1')).toBe(3);

    // 4th connection drops res1 (oldest)
    vi.advanceTimersByTime(10);
    hub.subscribe('user-1', res4, req4);

    expect(res1.end).toHaveBeenCalled();
    expect(hub.getUserConnectionCount('user-1')).toBe(3);
  });

  it('delivers events to targeted audience members only', async () => {
    const res1 = createMockResponse();
    const req1 = createMockRequest();
    const res2 = createMockResponse();
    const req2 = createMockRequest();
    const res3 = createMockResponse();
    const req3 = createMockRequest();

    hub.subscribe('user-1', res1, req1);
    hub.subscribe('user-2', res2, req2);
    hub.subscribe('user-3', res3, req3); // outside class

    await hub.publishToAudience(['user-1', 'user-2'], {
      type: 'session.started',
      sessionId: 'sess-1',
      classGroupId: 'class-1',
      at: new Date().toISOString(),
    });

    const hasEvent1 = res1.written.some((w) => w.includes('session.started'));
    const hasEvent2 = res2.written.some((w) => w.includes('session.started'));
    const hasEvent3 = res3.written.some((w) => w.includes('session.started'));

    expect(hasEvent1).toBe(true);
    expect(hasEvent2).toBe(true);
    expect(hasEvent3).toBe(false);
  });

  it('publishes event to class audience using ClassAccessPort', async () => {
    const res1 = createMockResponse();
    const req1 = createMockRequest();

    hub.subscribe('user-1', res1, req1);

    await hub.publishToClass('class-1', {
      type: 'session.created',
      sessionId: 'sess-1',
      classGroupId: 'class-1',
      at: new Date().toISOString(),
    });

    expect(mockClassAccess.getClassMemberUserIds).toHaveBeenCalledWith('class-1');
    const hasEvent = res1.written.some((w) => w.includes('session.created'));
    expect(hasEvent).toBe(true);
  });

  it('respects optional sessionId filter on client connection', async () => {
    const resAll = createMockResponse();
    const reqAll = createMockRequest();
    const resSess1Only = createMockResponse();
    const reqSess1Only = createMockRequest();

    hub.subscribe('user-1', resAll, reqAll);
    hub.subscribe('user-1', resSess1Only, reqSess1Only, 'sess-1');

    await hub.publishToAudience(['user-1'], {
      type: 'session.chat-message-created',
      sessionId: 'sess-2',
      classGroupId: 'class-1',
      at: new Date().toISOString(),
    });

    const allReceived = resAll.written.some((w) => w.includes('sess-2'));
    const filteredReceived = resSess1Only.written.some((w) => w.includes('sess-2'));

    expect(allReceived).toBe(true);
    expect(filteredReceived).toBe(false);
  });

  it('cleans up connections when req emits close', () => {
    const res = createMockResponse();
    const req = createMockRequest();

    hub.subscribe('user-1', res, req);
    expect(hub.getUserConnectionCount('user-1')).toBe(1);

    req.emit('close');
    expect(hub.getUserConnectionCount('user-1')).toBe(0);
    expect(hub.getActiveConnectionCount()).toBe(0);
  });
});

describe('GetMyNextSessionUseCase', () => {
  let useCase: GetMyNextSessionUseCase;
  let mockSessionRepo: Partial<VideoSessionRepositoryPort>;
  let mockClassAccess: Partial<ClassAccessPort>;
  let mockClock: ClockPort;

  const now = new Date('2026-10-25T14:00:00.000Z');

  beforeEach(() => {
    mockClock = { now: () => now };
    mockClassAccess = {
      getUserClassGroupIds: vi.fn().mockResolvedValue(['class-1', 'class-2']),
    };
    mockSessionRepo = {
      findUpcomingOrLiveForClasses: vi.fn().mockResolvedValue({
        live: null,
        upcoming: null,
      }),
    };

    useCase = new GetMyNextSessionUseCase(
      mockSessionRepo as VideoSessionRepositoryPort,
      mockClassAccess as ClassAccessPort,
      mockClock,
    );
  });

  const makeMockSession = (overrides: Partial<VideoSession> = {}): VideoSession => ({
    id: 'sess-1',
    classGroupId: 'class-1',
    hostId: 'host-1',
    hostName: 'Professeur Dupont',
    subject: 'Mathématiques',
    title: 'Algèbre Linéaire',
    description: 'Cours magistral',
    startsAt: new Date('2026-10-25T15:00:00.000Z'),
    endsAt: new Date('2026-10-25T16:00:00.000Z'),
    startedAt: null,
    endedAt: null,
    status: 'SCHEDULED',
    roomName: 'room-abc',
    joinOpensMinutesBefore: 5,
    chatEnabled: true,
    timetableSlotId: null,
    courseId: null,
    cancelReason: null,
    createdAt: now,
    updatedAt: now,
    ...overrides,
  });

  it('returns empty nulls when caller has no assigned or enrolled classes', async () => {
    vi.mocked(mockClassAccess.getUserClassGroupIds!).mockResolvedValueOnce([]);

    const result = await useCase.execute({
      userId: 'student-empty',
      role: 'STUDENT',
    });

    expect(result).toEqual({
      liveSession: null,
      upcomingSession: null,
      serverNow: now.toISOString(),
    });
    expect(mockSessionRepo.findUpcomingOrLiveForClasses).not.toHaveBeenCalled();
  });

  it('queries all classes when caller has ADMIN role', async () => {
    const liveSession = makeMockSession({
      id: 'sess-live',
      status: 'IN_PROGRESS',
      startedAt: new Date('2026-10-25T13:55:00.000Z'),
    });

    vi.mocked(mockSessionRepo.findUpcomingOrLiveForClasses!).mockResolvedValueOnce({
      live: liveSession,
      upcoming: null,
    });

    const result = await useCase.execute({
      userId: 'admin-1',
      role: 'ADMIN',
    });

    expect(mockClassAccess.getUserClassGroupIds).not.toHaveBeenCalled();
    expect(mockSessionRepo.findUpcomingOrLiveForClasses).toHaveBeenCalledWith([], now, 24);
    expect(result.liveSession?.id).toBe('sess-live');
    expect(result.upcomingSession).toBeNull();
  });

  it('returns both live and upcoming sessions mapped to DTOs', async () => {
    const liveSession = makeMockSession({
      id: 'sess-live',
      status: 'IN_PROGRESS',
      startedAt: new Date('2026-10-25T13:50:00.000Z'),
    });
    const upcomingSession = makeMockSession({
      id: 'sess-upcoming',
      status: 'SCHEDULED',
      startsAt: new Date('2026-10-25T17:00:00.000Z'),
      endsAt: new Date('2026-10-25T18:00:00.000Z'),
    });

    vi.mocked(mockSessionRepo.findUpcomingOrLiveForClasses!).mockResolvedValueOnce({
      live: liveSession,
      upcoming: upcomingSession,
    });

    const result = await useCase.execute({
      userId: 'student-1',
      role: 'STUDENT',
      horizonHours: 12,
    });

    expect(mockSessionRepo.findUpcomingOrLiveForClasses).toHaveBeenCalledWith(
      ['class-1', 'class-2'],
      now,
      12,
    );
    expect(result.liveSession?.id).toBe('sess-live');
    expect(result.liveSession?.status).toBe('IN_PROGRESS');
    expect(result.upcomingSession?.id).toBe('sess-upcoming');
    expect(result.upcomingSession?.status).toBe('SCHEDULED');
    expect(result.serverNow).toBe(now.toISOString());
  });

  it('clamps horizonHours between 1 and 72', async () => {
    await useCase.execute({
      userId: 'teacher-1',
      role: 'TEACHER',
      horizonHours: 100, // beyond max 72
    });

    expect(mockSessionRepo.findUpcomingOrLiveForClasses).toHaveBeenCalledWith(
      ['class-1', 'class-2'],
      now,
      72,
    );

    await useCase.execute({
      userId: 'teacher-1',
      role: 'TEACHER',
      horizonHours: -5, // below min 1
    });

    expect(mockSessionRepo.findUpcomingOrLiveForClasses).toHaveBeenCalledWith(
      ['class-1', 'class-2'],
      now,
      1,
    );
  });
});
