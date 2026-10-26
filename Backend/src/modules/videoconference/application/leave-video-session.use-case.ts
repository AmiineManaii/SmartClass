import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { SessionParticipantRepositoryPort } from '../domain/session-participant-repository.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { NotFoundError } from '../../../shared/errors/app-error.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class LeaveVideoSessionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly participantRepository: SessionParticipantRepositoryPort,
    private readonly clock: ClockPort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<{ left: boolean }> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      const now = this.clock.now();
      await this.participantRepository.recordLeave(sessionId, user.id, now);

      try {
        await this.eventsPublisher?.publishToClass(session.classGroupId, {
          type: 'session.participant-left',
          sessionId: session.id,
          classGroupId: session.classGroupId,
          status: session.status,
          at: now.toISOString(),
          data: { userId: user.id },
        });
      } catch {
        // Best-effort realtime publish
      }

      return { left: true };
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
