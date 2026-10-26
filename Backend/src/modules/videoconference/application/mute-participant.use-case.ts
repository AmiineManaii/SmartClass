import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { RoomServicePort } from '../domain/room-service.port.js';
import { SessionAccessDeniedDomainError } from '../domain/domain-errors.js';
import {
  NotFoundError,
  ServiceUnavailableError,
} from '../../../shared/errors/app-error.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class MuteParticipantUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly roomService?: RoomServicePort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    targetUserId: string,
  ): Promise<{ muted: boolean }> {
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
          'Only the host or admin can mute participants',
        );
      }

      await this.roomService.muteParticipant(session.roomName, targetUserId);
      return { muted: true };
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
