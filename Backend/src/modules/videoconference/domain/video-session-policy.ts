import type { VideoSession } from './video-session.entity.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export interface ClassAccessContext {
  isMember: boolean;
  isTeacherAssigned: boolean;
  isReferent: boolean;
  isApprovedTeacher: boolean;
}

export interface JoinEvaluation {
  allowed: boolean;
  reason?: 'NOT_A_MEMBER' | 'BANNED' | 'NOT_STARTED' | 'ENDED' | 'CANCELED';
  joinOpensAt?: Date;
}

/**
 * Checks if a user is authorized to create, edit, start, end, or moderate sessions for a class.
 * Authorized if:
 * 1. User is an ADMIN
 * 2. User is an approved TEACHER who is either assigned to the class or is its referent
 */
export const canHost = (user: UserContext, access: ClassAccessContext): boolean => {
  if (user.role === 'ADMIN') {
    return true;
  }

  if (user.role === 'TEACHER' && access.isApprovedTeacher) {
    return access.isTeacherAssigned || access.isReferent;
  }

  return false;
};

/**
 * Checks whether the host/admin can trigger the session start.
 * Allowed up to 60 minutes before startsAt.
 */
export const canStart = (
  user: UserContext,
  session: VideoSession,
  access: ClassAccessContext,
  now: Date,
): boolean => {
  if (!canHost(user, access)) {
    return false;
  }

  if (session.status !== 'SCHEDULED') {
    return false;
  }

  if (now.getTime() >= session.endsAt.getTime()) {
    return false;
  }

  // Host can start up to 60 minutes before scheduled startsAt
  const earliestStartMs = session.startsAt.getTime() - 60 * 60 * 1000;
  return now.getTime() >= earliestStartMs;
};

/**
 * Evaluates whether a user can obtain a LiveKit join token to enter the media room.
 */
export const evaluateJoinPermission = (
  user: UserContext,
  session: VideoSession,
  access: ClassAccessContext,
  isRemoved: boolean,
  now: Date,
): JoinEvaluation => {
  // 1. Persistent removal restriction check
  if (isRemoved) {
    return { allowed: false, reason: 'BANNED' };
  }

  // 2. Class membership check (ADMIN exempt)
  const isEnrolledOrAssigned = access.isMember || access.isTeacherAssigned || access.isReferent;
  if (user.role !== 'ADMIN' && !isEnrolledOrAssigned) {
    return { allowed: false, reason: 'NOT_A_MEMBER' };
  }

  // If session end time has passed, nobody can enter
  if (now.getTime() >= session.endsAt.getTime()) {
    return { allowed: false, reason: 'ENDED' };
  }

  // 3. Status checks
  if (session.status === 'CANCELED') {
    return { allowed: false, reason: 'CANCELED' };
  }

  if (session.status === 'COMPLETED') {
    return { allowed: false, reason: 'ENDED' };
  }

  // If session is already live, authorized users can join
  if (session.status === 'IN_PROGRESS') {
    return { allowed: true };
  }

  // Session is SCHEDULED
  // If user is the host or admin, they can join early to prepare the room
  const isHostOrAdmin = user.role === 'ADMIN' || (user.id === session.hostId && canHost(user, access));
  if (isHostOrAdmin) {
    const earliestHostJoinMs = session.startsAt.getTime() - 60 * 60 * 1000;
    if (now.getTime() >= earliestHostJoinMs) {
      return { allowed: true };
    }
  }

  // For students and general participants, LiveKit connection is strictly blocked until session is IN_PROGRESS
  const joinOpensAt = new Date(session.startsAt.getTime() - session.joinOpensMinutesBefore * 60 * 1000);
  return {
    allowed: false,
    reason: 'NOT_STARTED',
    joinOpensAt,
  };
};

/**
 * Checks if two time intervals [startA, endA] and [startB, endB] overlap.
 */
export const hasTimeOverlap = (
  startA: Date,
  endA: Date,
  startB: Date,
  endB: Date,
): boolean => {
  return startA.getTime() < endB.getTime() && endA.getTime() > startB.getTime();
};
