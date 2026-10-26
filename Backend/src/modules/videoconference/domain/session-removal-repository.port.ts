import type { SessionParticipantRemoval } from './video-session.entity.js';

export interface SessionRemovalRepositoryPort {
  recordRemoval(
    removal: Omit<SessionParticipantRemoval, 'id' | 'removedAt'>,
  ): Promise<SessionParticipantRemoval>;
  isUserRemoved(sessionId: string, userId: string): Promise<boolean>;
}
