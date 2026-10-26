import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { SessionParticipantRepositoryPort } from '../domain/session-participant-repository.port.js';
import type { SessionParticipant } from '../domain/video-session.entity.js';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/app-error.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class ListSessionParticipantsUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly participantRepository: SessionParticipantRepositoryPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<SessionParticipant[]> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      const isHost = session.hostId === user.id;
      const isAdmin = user.role === 'ADMIN';

      if (!isAdmin && !isHost) {
        throw new ForbiddenError(
          'Only the host or admin can view session attendance intervals',
        );
      }

      return this.participantRepository.listBySession(sessionId);
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
