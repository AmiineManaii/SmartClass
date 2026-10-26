import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { canHost } from '../domain/video-session-policy.js';
import { transitionVideoSession } from '../domain/video-session-lifecycle.js';
import { SessionAccessDeniedDomainError } from '../domain/domain-errors.js';
import { NotFoundError, ConflictError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface CancelVideoSessionInput {
  reason?: string | null;
  cancelReason?: string | null;
}

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class CancelVideoSessionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    input: CancelVideoSessionInput,
  ): Promise<VideoSessionDto> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      const isHost = session.hostId === user.id;
      const isAdmin = user.role === 'ADMIN';

      if (!isAdmin && !isHost) {
        throw new SessionAccessDeniedDomainError(
          'Only the host or admin can cancel this session',
        );
      }

      if (!isAdmin) {
        const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
        if (!canHost(user, access)) {
          throw new SessionAccessDeniedDomainError(
            'User is not authorized to manage sessions for this class',
          );
        }
      }

      const reason = (input.reason ?? input.cancelReason)?.trim() || null;

      // Pure domain validation of state transition
      transitionVideoSession(session, 'CANCELED', { cancelReason: reason ?? undefined });

      const updated = await this.sessionRepository.updateStatusAtomic(
        sessionId,
        'SCHEDULED',
        'CANCELED',
        { cancelReason: reason ?? undefined },
      );

      if (!updated) {
        throw new ConflictError(
          'Session could not be canceled. Current status may have changed.',
        );
      }

      await this.auditService?.record({
        userId: user.id,
        action: 'session.canceled',
        targetType: 'VideoSession',
        targetId: updated.id,
        details: {
          classGroupId: updated.classGroupId,
          title: updated.title,
          cancelReason: reason,
        },
      });

      try {
        await this.eventsPublisher?.publishToClass(updated.classGroupId, {
          type: 'session.canceled',
          sessionId: updated.id,
          classGroupId: updated.classGroupId,
          status: updated.status,
          startsAt: updated.startsAt.toISOString(),
          endsAt: updated.endsAt.toISOString(),
          at: new Date().toISOString(),
        });
      } catch {
        // Never fail request if SSE publish fails
      }

      return toVideoSessionDto(updated);
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
