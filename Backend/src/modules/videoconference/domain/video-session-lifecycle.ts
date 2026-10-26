import type { VideoSession, VideoSessionStatus, SessionPhase } from './video-session.entity.js';
import { InvalidStateTransitionDomainError } from './domain-errors.js';

/**
 * Pure calculation of the user-facing session phase.
 * Note: Keep this implementation identical to the Flutter counterpart in Phase 5.
 */
export const sessionPhase = (
  session: Pick<VideoSession, 'status' | 'startsAt' | 'endsAt' | 'joinOpensMinutesBefore'>,
  now: Date,
): SessionPhase => {
  if (session.status === 'CANCELED') {
    return 'CANCELED';
  }

  if (session.status === 'COMPLETED') {
    return 'ENDED';
  }

  if (session.status === 'IN_PROGRESS') {
    return 'LIVE';
  }

  // Session is SCHEDULED
  const joinOpensMs = session.startsAt.getTime() - session.joinOpensMinutesBefore * 60 * 1000;
  const nowMs = now.getTime();

  if (nowMs >= session.endsAt.getTime()) {
    return 'ENDED';
  }

  if (nowMs >= joinOpensMs) {
    return 'JOIN_OPEN';
  }

  return 'UPCOMING';
};

export interface TransitionMeta {
  startedAt?: Date;
  endedAt?: Date;
  cancelReason?: string;
}

/**
 * Pure lifecycle state machine transition.
 * Permitted transitions:
 * - SCHEDULED -> IN_PROGRESS
 * - SCHEDULED -> CANCELED
 * - IN_PROGRESS -> COMPLETED
 */
export const transitionVideoSession = (
  session: VideoSession,
  targetStatus: VideoSessionStatus,
  meta?: TransitionMeta,
): VideoSession => {
  const current = session.status;

  if (current === targetStatus) {
    return session;
  }

  if (current === 'SCHEDULED' && targetStatus === 'IN_PROGRESS') {
    return {
      ...session,
      status: 'IN_PROGRESS',
      startedAt: meta?.startedAt ?? new Date(),
      updatedAt: new Date(),
    };
  }

  if (current === 'SCHEDULED' && targetStatus === 'CANCELED') {
    return {
      ...session,
      status: 'CANCELED',
      cancelReason: meta?.cancelReason ?? null,
      updatedAt: new Date(),
    };
  }

  if (current === 'IN_PROGRESS' && targetStatus === 'COMPLETED') {
    return {
      ...session,
      status: 'COMPLETED',
      endedAt: meta?.endedAt ?? new Date(),
      updatedAt: new Date(),
    };
  }

  throw new InvalidStateTransitionDomainError(current, targetStatus);
};
