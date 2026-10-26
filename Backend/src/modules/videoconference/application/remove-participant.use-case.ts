import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { SessionRemovalRepositoryPort } from '../domain/session-removal-repository.port.js';
import type { SessionParticipantRepositoryPort } from '../domain/session-participant-repository.port.js';
import type { RoomServicePort } from '../domain/room-service.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import { SessionAccessDeniedDomainError } from '../domain/domain-errors.js';
import {
  NotFoundError,
  ForbiddenError,
  ConflictError,
  ServiceUnavailableError,
} from '../../../shared/errors/app-error.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class RemoveParticipantUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly removalRepository: SessionRemovalRepositoryPort,
    private readonly participantRepository: SessionParticipantRepositoryPort,
    private readonly clock: ClockPort,
    private readonly roomService?: RoomServicePort,
    private readonly auditService?: AuditServicePort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    targetUserId: string,
    reason?: string | null,
  ): Promise<{ removed: boolean }> {
    try {
      if (!this.roomService) {
        throw new ServiceUnavailableError('Live service not configured');
      }

      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      const isHost = session.hostId === user.id;
      const isAdmin = user.role === 'ADMIN';

      if (!isAdmin && !isHost) {
        throw new SessionAccessDeniedDomainError(
          'Only the host or admin can remove participants',
        );
      }

      if (targetUserId === user.id) {
        throw new ConflictError('Cannot remove yourself from the live session');
      }

      if (targetUserId === session.hostId) {
        throw new ForbiddenError('Cannot remove the session host');
      }

      const now = this.clock.now();

      // 1. Record persistent removal (blocks rejoining)
      await this.removalRepository.recordRemoval({
        sessionId,
        userId: targetUserId,
        removedById: user.id,
        reason: reason?.trim() || null,
      });

      // 2. Close active attendance interval
      await this.participantRepository.recordLeave(sessionId, targetUserId, now);

      // 3. Force disconnect from LiveKit room
      await this.roomService.removeParticipant(session.roomName, targetUserId);

      await this.auditService?.record({
        userId: user.id,
        action: 'participant.removed',
        targetType: 'VideoSession',
        targetId: session.id,
        details: {
          removedUserId: targetUserId,
          reason: reason?.trim() || null,
        },
      });

      return { removed: true };
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
