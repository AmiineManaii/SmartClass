import type { SessionParticipant } from './video-session.entity.js';

export interface SessionParticipantRepositoryPort {
  recordJoin(sessionId: string, userId: string, joinedAt: Date): Promise<SessionParticipant>;
  recordLeave(sessionId: string, userId: string, leftAt: Date): Promise<SessionParticipant | null>;
  listBySession(sessionId: string): Promise<SessionParticipant[]>;
  countActiveBySession(sessionId: string): Promise<number>;
}
