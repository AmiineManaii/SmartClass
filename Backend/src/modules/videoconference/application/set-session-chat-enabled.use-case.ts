import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class SetSessionChatEnabledUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly clock: ClockPort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    enabled: boolean,
  ): Promise<VideoSessionDto> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      const isHost = session.hostId === user.id;
      const isAdmin = user.role === 'ADMIN';

      if (!isAdmin && !isHost) {
        throw new ForbiddenError(
          'Only the host or admin can toggle chat permissions',
        );
      }

      const updatedSession = {
        ...session,
        chatEnabled: enabled,
        updatedAt: this.clock.now(),
      };

      const result = await this.sessionRepository.update(updatedSession);

      await this.auditService?.record({
        userId: user.id,
        action: 'session.chat_settings_updated',
        targetType: 'VideoSession',
        targetId: result.id,
        details: {
          chatEnabled: enabled,
        },
      });

      try {
        await this.eventsPublisher?.publishToClass(result.classGroupId, {
          type: 'session.chat-settings-updated',
          sessionId: result.id,
          classGroupId: result.classGroupId,
          status: result.status,
          at: this.clock.now().toISOString(),
          data: {
            chatEnabled: enabled,
          },
        });
      } catch {
        // Never fail request if SSE publish fails
      }

      return toVideoSessionDto(result);
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
