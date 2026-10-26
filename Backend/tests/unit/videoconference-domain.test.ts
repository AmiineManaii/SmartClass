import { describe, it, expect } from 'vitest';
import type { VideoSession } from '../../src/modules/videoconference/domain/video-session.entity.js';
import {
  sessionPhase,
  transitionVideoSession,
} from '../../src/modules/videoconference/domain/video-session-lifecycle.js';
import {
  validateSessionSchedule,
  validateSessionTitle,
  validateChatMessageContent,
} from '../../src/modules/videoconference/domain/video-session-validation.js';
import {
  canHost,
  canStart,
  evaluateJoinPermission,
  hasTimeOverlap,
} from '../../src/modules/videoconference/domain/video-session-policy.js';
import {
  InvalidStateTransitionDomainError,
  SessionValidationDomainError,
} from '../../src/modules/videoconference/domain/domain-errors.js';

describe('Videoconference Pure Domain', () => {
  const baseTime = new Date('2026-10-26T10:00:00.000Z');

  const makeSession = (overrides: Partial<VideoSession> = {}): VideoSession => ({
    id: '11111111-1111-4111-a111-111111111111',
    classGroupId: '22222222-2222-4222-a222-222222222222',
    hostId: '33333333-3333-4333-a333-333333333333',
    subject: 'Mathématiques',
    title: 'Algèbre linéaire',
    description: 'Cours magistral',
    startsAt: new Date('2026-10-26T10:00:00.000Z'),
    endsAt: new Date('2026-10-26T11:00:00.000Z'),
    startedAt: null,
    endedAt: null,
    status: 'SCHEDULED',
    roomName: 'room-test-123',
    joinOpensMinutesBefore: 5,
    chatEnabled: true,
    timetableSlotId: null,
    courseId: null,
    cancelReason: null,
    createdAt: new Date('2026-10-25T10:00:00.000Z'),
    updatedAt: new Date('2026-10-25T10:00:00.000Z'),
    ...overrides,
  });

  describe('Lifecycle State Machine', () => {
    it('transitions from SCHEDULED to IN_PROGRESS and records startedAt', () => {
      const session = makeSession({ status: 'SCHEDULED' });
      const startedAt = new Date('2026-10-26T09:55:00.000Z');

      const updated = transitionVideoSession(session, 'IN_PROGRESS', { startedAt });

      expect(updated.status).toBe('IN_PROGRESS');
      expect(updated.startedAt).toEqual(startedAt);
    });

    it('transitions from SCHEDULED to CANCELED and records cancelReason', () => {
      const session = makeSession({ status: 'SCHEDULED' });
      const updated = transitionVideoSession(session, 'CANCELED', {
        cancelReason: 'Professeur malade',
      });

      expect(updated.status).toBe('CANCELED');
      expect(updated.cancelReason).toBe('Professeur malade');
    });

    it('transitions from IN_PROGRESS to COMPLETED and records endedAt', () => {
      const session = makeSession({
        status: 'IN_PROGRESS',
        startedAt: new Date('2026-10-26T09:55:00.000Z'),
      });
      const endedAt = new Date('2026-10-26T11:05:00.000Z');

      const updated = transitionVideoSession(session, 'COMPLETED', { endedAt });

      expect(updated.status).toBe('COMPLETED');
      expect(updated.endedAt).toEqual(endedAt);
    });

    it('returns the same session if transitioning to current status (idempotent)', () => {
      const session = makeSession({ status: 'IN_PROGRESS' });
      const updated = transitionVideoSession(session, 'IN_PROGRESS');
      expect(updated).toBe(session);
    });

    it('rejects invalid state transitions with InvalidStateTransitionDomainError', () => {
      // Cannot jump from SCHEDULED to COMPLETED directly
      const scheduled = makeSession({ status: 'SCHEDULED' });
      expect(() => transitionVideoSession(scheduled, 'COMPLETED')).toThrow(
        InvalidStateTransitionDomainError,
      );

      // Cannot cancel an active session
      const inProgress = makeSession({ status: 'IN_PROGRESS' });
      expect(() => transitionVideoSession(inProgress, 'CANCELED')).toThrow(
        InvalidStateTransitionDomainError,
      );

      // Terminal state: COMPLETED cannot transition to anything
      const completed = makeSession({ status: 'COMPLETED' });
      expect(() => transitionVideoSession(completed, 'IN_PROGRESS')).toThrow(
        InvalidStateTransitionDomainError,
      );
      expect(() => transitionVideoSession(completed, 'SCHEDULED')).toThrow(
        InvalidStateTransitionDomainError,
      );

      // Terminal state: CANCELED cannot transition to anything
      const canceled = makeSession({ status: 'CANCELED' });
      expect(() => transitionVideoSession(canceled, 'IN_PROGRESS')).toThrow(
        InvalidStateTransitionDomainError,
      );
    });
  });

  describe('sessionPhase Calculation', () => {
    it('returns CANCELED if session is canceled', () => {
      const session = makeSession({ status: 'CANCELED' });
      expect(sessionPhase(session, baseTime)).toBe('CANCELED');
    });

    it('returns ENDED if session is completed', () => {
      const session = makeSession({ status: 'COMPLETED' });
      expect(sessionPhase(session, baseTime)).toBe('ENDED');
    });

    it('returns LIVE if session status is IN_PROGRESS', () => {
      const session = makeSession({ status: 'IN_PROGRESS' });
      expect(sessionPhase(session, baseTime)).toBe('LIVE');
    });

    it('returns UPCOMING when scheduled and before join window', () => {
      // startsAt = 10:00, joinOpensMinutesBefore = 5 -> join opens at 09:55
      const session = makeSession({
        status: 'SCHEDULED',
        startsAt: new Date('2026-10-26T10:00:00.000Z'),
        endsAt: new Date('2026-10-26T11:00:00.000Z'),
        joinOpensMinutesBefore: 5,
      });

      // At 09:50 -> UPCOMING
      const now = new Date('2026-10-26T09:50:00.000Z');
      expect(sessionPhase(session, now)).toBe('UPCOMING');
    });

    it('returns JOIN_OPEN when scheduled and inside join window', () => {
      const session = makeSession({
        status: 'SCHEDULED',
        startsAt: new Date('2026-10-26T10:00:00.000Z'),
        endsAt: new Date('2026-10-26T11:00:00.000Z'),
        joinOpensMinutesBefore: 5,
      });

      // Exactly at 09:55:00
      const exactOpen = new Date('2026-10-26T09:55:00.000Z');
      expect(sessionPhase(session, exactOpen)).toBe('JOIN_OPEN');

      // At 09:58:00
      const inWindow = new Date('2026-10-26T09:58:00.000Z');
      expect(sessionPhase(session, inWindow)).toBe('JOIN_OPEN');
    });

    it('returns ENDED when scheduled session reaches or passes endsAt without starting', () => {
      const session = makeSession({
        status: 'SCHEDULED',
        startsAt: new Date('2026-10-26T10:00:00.000Z'),
        endsAt: new Date('2026-10-26T11:00:00.000Z'),
      });

      const pastEnd = new Date('2026-10-26T11:00:00.000Z');
      expect(sessionPhase(session, pastEnd)).toBe('ENDED');
    });
  });

  describe('Schedule Validation', () => {
    it('validates and computes endsAt from durationMinutes', () => {
      const now = new Date('2026-10-26T09:00:00.000Z');
      const startsAt = new Date('2026-10-26T10:00:00.000Z');

      const result = validateSessionSchedule({
        startsAt,
        durationMinutes: 90,
        joinOpensMinutesBefore: 10,
        now,
      });

      expect(result.durationMinutes).toBe(90);
      expect(result.endsAt).toEqual(new Date('2026-10-26T11:30:00.000Z'));
      expect(result.joinOpensMinutesBefore).toBe(10);
    });

    it('rejects joinOpensMinutesBefore outside 0..30', () => {
      const now = new Date('2026-10-26T09:00:00.000Z');
      const startsAt = new Date('2026-10-26T10:00:00.000Z');

      expect(() =>
        validateSessionSchedule({
          startsAt,
          joinOpensMinutesBefore: -1,
          now,
        }),
      ).toThrow(SessionValidationDomainError);

      expect(() =>
        validateSessionSchedule({
          startsAt,
          joinOpensMinutesBefore: 35,
          now,
        }),
      ).toThrow(SessionValidationDomainError);
    });

    it('rejects duration outside 5..480 minutes', () => {
      const now = new Date('2026-10-26T09:00:00.000Z');
      const startsAt = new Date('2026-10-26T10:00:00.000Z');

      expect(() =>
        validateSessionSchedule({
          startsAt,
          durationMinutes: 4,
          now,
        }),
      ).toThrow(SessionValidationDomainError);

      expect(() =>
        validateSessionSchedule({
          startsAt,
          durationMinutes: 481,
          now,
        }),
      ).toThrow(SessionValidationDomainError);
    });

    it('rejects endsAt <= startsAt', () => {
      const now = new Date('2026-10-26T09:00:00.000Z');
      const startsAt = new Date('2026-10-26T10:00:00.000Z');
      const endsAt = new Date('2026-10-26T09:59:00.000Z');

      expect(() =>
        validateSessionSchedule({
          startsAt,
          endsAt,
          now,
        }),
      ).toThrow(SessionValidationDomainError);
    });

    it('rejects scheduled startsAt in the past (> 1 min)', () => {
      const now = new Date('2026-10-26T10:00:00.000Z');
      const pastStartsAt = new Date('2026-10-26T09:55:00.000Z');

      expect(() =>
        validateSessionSchedule({
          startsAt: pastStartsAt,
          durationMinutes: 60,
          now,
          isStartNow: false,
        }),
      ).toThrow(SessionValidationDomainError);
    });

    it('allows start now even if startsAt is slightly behind current clock', () => {
      const now = new Date('2026-10-26T10:00:00.000Z');
      const startsAt = new Date('2026-10-26T09:58:00.000Z');

      const result = validateSessionSchedule({
        startsAt,
        durationMinutes: 60,
        now,
        isStartNow: true,
      });

      expect(result.startsAt).toEqual(startsAt);
    });

    it('rejects scheduled startsAt exceeding 365 days', () => {
      const now = new Date('2026-10-26T10:00:00.000Z');
      const tooFar = new Date('2027-11-01T10:00:00.000Z');

      expect(() =>
        validateSessionSchedule({
          startsAt: tooFar,
          durationMinutes: 60,
          now,
        }),
      ).toThrow(SessionValidationDomainError);
    });
  });

  describe('Title and Content Validation', () => {
    it('validates session title length (3..200)', () => {
      expect(validateSessionTitle('Mathématiques')).toBe('Mathématiques');
      expect(() => validateSessionTitle('ab')).toThrow(SessionValidationDomainError);
      expect(() => validateSessionTitle('   ')).toThrow(SessionValidationDomainError);
      expect(() => validateSessionTitle('a'.repeat(201))).toThrow(SessionValidationDomainError);
    });

    it('validates chat message content (1..2000)', () => {
      expect(validateChatMessageContent('Bonjour !')).toBe('Bonjour !');
      expect(() => validateChatMessageContent('')).toThrow(SessionValidationDomainError);
      expect(() => validateChatMessageContent('   ')).toThrow(SessionValidationDomainError);
      expect(() => validateChatMessageContent('x'.repeat(2001))).toThrow(
        SessionValidationDomainError,
      );
    });
  });

  describe('Policy: canHost', () => {
    it('grants host access to ADMIN regardless of class assignment', () => {
      const user = { id: 'u1', role: 'ADMIN' as const };
      const access = {
        isMember: false,
        isTeacherAssigned: false,
        isReferent: false,
        isApprovedTeacher: false,
      };
      expect(canHost(user, access)).toBe(true);
    });

    it('grants host access to approved TEACHER assigned to class', () => {
      const user = { id: 'u2', role: 'TEACHER' as const };
      const access = {
        isMember: false,
        isTeacherAssigned: true,
        isReferent: false,
        isApprovedTeacher: true,
      };
      expect(canHost(user, access)).toBe(true);
    });

    it('grants host access to approved TEACHER who is referent of class', () => {
      const user = { id: 'u3', role: 'TEACHER' as const };
      const access = {
        isMember: false,
        isTeacherAssigned: false,
        isReferent: true,
        isApprovedTeacher: true,
      };
      expect(canHost(user, access)).toBe(true);
    });

    it('denies host access to unapproved TEACHER even if assigned', () => {
      const user = { id: 'u4', role: 'TEACHER' as const };
      const access = {
        isMember: false,
        isTeacherAssigned: true,
        isReferent: false,
        isApprovedTeacher: false,
      };
      expect(canHost(user, access)).toBe(false);
    });

    it('denies host access to STUDENT', () => {
      const user = { id: 'u5', role: 'STUDENT' as const };
      const access = {
        isMember: true,
        isTeacherAssigned: false,
        isReferent: false,
        isApprovedTeacher: false,
      };
      expect(canHost(user, access)).toBe(false);
    });
  });

  describe('Policy: canStart', () => {
    it('allows host to start up to 60 minutes before startsAt', () => {
      const user = { id: 't1', role: 'TEACHER' as const };
      const access = {
        isMember: false,
        isTeacherAssigned: true,
        isReferent: false,
        isApprovedTeacher: true,
      };
      const session = makeSession({
        hostId: 't1',
        status: 'SCHEDULED',
        startsAt: new Date('2026-10-26T10:00:00.000Z'),
      });

      // 59 minutes before -> allowed
      const at59MinBefore = new Date('2026-10-26T09:01:00.000Z');
      expect(canStart(user, session, access, at59MinBefore)).toBe(true);

      // 61 minutes before -> too early
      const at61MinBefore = new Date('2026-10-26T08:59:00.000Z');
      expect(canStart(user, session, access, at61MinBefore)).toBe(false);
    });

    it('denies start if session is not SCHEDULED', () => {
      const user = { id: 't1', role: 'TEACHER' as const };
      const access = {
        isMember: false,
        isTeacherAssigned: true,
        isReferent: false,
        isApprovedTeacher: true,
      };
      const session = makeSession({ hostId: 't1', status: 'IN_PROGRESS' });
      expect(canStart(user, session, access, new Date())).toBe(false);
    });
  });

  describe('Policy: evaluateJoinPermission', () => {
    it('blocks removed/banned participant with BANNED', () => {
      const user = { id: 's1', role: 'STUDENT' as const };
      const access = {
        isMember: true,
        isTeacherAssigned: false,
        isReferent: false,
        isApprovedTeacher: false,
      };
      const session = makeSession({ status: 'IN_PROGRESS' });

      const result = evaluateJoinPermission(user, session, access, true, baseTime);
      expect(result.allowed).toBe(false);
      expect(result.reason).toBe('BANNED');
    });

    it('blocks outsider with NOT_A_MEMBER', () => {
      const user = { id: 's2', role: 'STUDENT' as const };
      const access = {
        isMember: false,
        isTeacherAssigned: false,
        isReferent: false,
        isApprovedTeacher: false,
      };
      const session = makeSession({ status: 'IN_PROGRESS' });

      const result = evaluateJoinPermission(user, session, access, false, baseTime);
      expect(result.allowed).toBe(false);
      expect(result.reason).toBe('NOT_A_MEMBER');
    });

    it('blocks join to CANCELED or COMPLETED session', () => {
      const user = { id: 's3', role: 'STUDENT' as const };
      const access = {
        isMember: true,
        isTeacherAssigned: false,
        isReferent: false,
        isApprovedTeacher: false,
      };

      const canceled = makeSession({ status: 'CANCELED' });
      expect(evaluateJoinPermission(user, canceled, access, false, baseTime).reason).toBe(
        'CANCELED',
      );

      const completed = makeSession({ status: 'COMPLETED' });
      expect(evaluateJoinPermission(user, completed, access, false, baseTime).reason).toBe('ENDED');
    });

    it('allows enrolled student when session is IN_PROGRESS', () => {
      const user = { id: 's4', role: 'STUDENT' as const };
      const access = {
        isMember: true,
        isTeacherAssigned: false,
        isReferent: false,
        isApprovedTeacher: false,
      };
      const session = makeSession({ status: 'IN_PROGRESS' });

      const result = evaluateJoinPermission(user, session, access, false, baseTime);
      expect(result.allowed).toBe(true);
    });

    it('blocks student when session is SCHEDULED, providing joinOpensAt', () => {
      const user = { id: 's5', role: 'STUDENT' as const };
      const access = {
        isMember: true,
        isTeacherAssigned: false,
        isReferent: false,
        isApprovedTeacher: false,
      };
      const session = makeSession({
        status: 'SCHEDULED',
        startsAt: new Date('2026-10-26T10:00:00.000Z'),
        joinOpensMinutesBefore: 5,
      });

      const result = evaluateJoinPermission(user, session, access, false, baseTime);
      expect(result.allowed).toBe(false);
      expect(result.reason).toBe('NOT_STARTED');
      expect(result.joinOpensAt).toEqual(new Date('2026-10-26T09:55:00.000Z'));
    });

    it('allows host to join SCHEDULED session up to 60 minutes early to prepare room', () => {
      const user = { id: 't1', role: 'TEACHER' as const };
      const access = {
        isMember: false,
        isTeacherAssigned: true,
        isReferent: false,
        isApprovedTeacher: true,
      };
      const session = makeSession({
        hostId: 't1',
        status: 'SCHEDULED',
        startsAt: new Date('2026-10-26T10:00:00.000Z'),
      });

      // At 09:30 (30 min before start)
      const now = new Date('2026-10-26T09:30:00.000Z');
      const result = evaluateJoinPermission(user, session, access, false, now);
      expect(result.allowed).toBe(true);
    });
  });

  describe('Policy: Time Overlap Detection', () => {
    it('detects overlapping intervals correctly', () => {
      const s1 = new Date('2026-10-26T10:00:00.000Z');
      const e1 = new Date('2026-10-26T11:00:00.000Z');

      // Fully overlapping
      expect(
        hasTimeOverlap(s1, e1, new Date('2026-10-26T10:15:00.000Z'), new Date('2026-10-26T10:45:00.000Z')),
      ).toBe(true);

      // Overlapping start
      expect(
        hasTimeOverlap(s1, e1, new Date('2026-10-26T09:30:00.000Z'), new Date('2026-10-26T10:30:00.000Z')),
      ).toBe(true);

      // Overlapping end
      expect(
        hasTimeOverlap(s1, e1, new Date('2026-10-26T10:30:00.000Z'), new Date('2026-10-26T11:30:00.000Z')),
      ).toBe(true);

      // Adjacent (boundary touching) -> no overlap
      expect(
        hasTimeOverlap(s1, e1, new Date('2026-10-26T11:00:00.000Z'), new Date('2026-10-26T12:00:00.000Z')),
      ).toBe(false);
      expect(
        hasTimeOverlap(s1, e1, new Date('2026-10-26T09:00:00.000Z'), new Date('2026-10-26T10:00:00.000Z')),
      ).toBe(false);

      // Completely disjoint
      expect(
        hasTimeOverlap(s1, e1, new Date('2026-10-26T14:00:00.000Z'), new Date('2026-10-26T15:00:00.000Z')),
      ).toBe(false);
    });
  });
});
