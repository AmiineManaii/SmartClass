import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import type { VideoSession } from '../domain/video-session.entity.js';
import { canHost } from '../domain/video-session-policy.js';
import {
  validateSessionSchedule,
  validateSessionTitle,
} from '../domain/video-session-validation.js';
import {
  SessionAccessDeniedDomainError,
  SessionConflictDomainError,
  SessionValidationDomainError,
} from '../domain/domain-errors.js';
import { NotFoundError, ConflictError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UpdateVideoSessionInput {
  title?: string;
  description?: string | null;
  subject?: string | null;
  startsAt?: string;
  endsAt?: string;
  durationMinutes?: number;
  joinOpensMinutesBefore?: number;
  chatEnabled?: boolean;
}

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class UpdateVideoSessionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly clock: ClockPort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    input: UpdateVideoSessionInput,
  ): Promise<VideoSessionDto> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      if (session.status !== 'SCHEDULED') {
        throw new ConflictError('Only scheduled sessions can be updated');
      }

      const isHost = session.hostId === user.id;
      const isAdmin = user.role === 'ADMIN';

      if (!isAdmin && !isHost) {
        throw new SessionAccessDeniedDomainError(
          'Only the host or admin can update this session',
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

      let title = session.title;
      if (input.title !== undefined) {
        title = validateSessionTitle(input.title);
      }

      let startsAt = session.startsAt;
      let endsAt = session.endsAt;
      let joinOpensMinutesBefore = session.joinOpensMinutesBefore;

      let calculatedDuration = input.durationMinutes;
      if (calculatedDuration === undefined && input.endsAt) {
        const startMs = input.startsAt
          ? new Date(input.startsAt).getTime()
          : session.startsAt.getTime();
        const endMs = new Date(input.endsAt).getTime();
        if (!Number.isNaN(startMs) && !Number.isNaN(endMs) && endMs > startMs) {
          calculatedDuration = Math.round((endMs - startMs) / (60 * 1000));
        }
      }

      const scheduleChanged =
        input.startsAt !== undefined ||
        input.endsAt !== undefined ||
        calculatedDuration !== undefined ||
        input.joinOpensMinutesBefore !== undefined;

      if (scheduleChanged) {
        if (input.startsAt) {
          startsAt = new Date(input.startsAt);
          if (Number.isNaN(startsAt.getTime())) {
            throw new SessionValidationDomainError('Invalid startsAt timestamp', 'startsAt');
          }
        }

        const currentDurationMinutes = Math.round(
          (session.endsAt.getTime() - session.startsAt.getTime()) / (60 * 1000),
        );
        const durationMinutes = calculatedDuration ?? currentDurationMinutes;

        const schedule = validateSessionSchedule({
          startsAt,
          durationMinutes,
          joinOpensMinutesBefore: input.joinOpensMinutesBefore ?? session.joinOpensMinutesBefore,
          now: this.clock.now(),
          isStartNow: false,
        });

        startsAt = schedule.startsAt;
        endsAt = schedule.endsAt;
        joinOpensMinutesBefore = schedule.joinOpensMinutesBefore;

        const overlapping = await this.sessionRepository.findOverlappingForClass(
          session.classGroupId,
          startsAt,
          endsAt,
          session.id,
        );
        if (overlapping.length > 0) {
          throw new SessionConflictDomainError(
            'A session is already scheduled for this class during this time interval',
          );
        }
      }

      const updatedSession: VideoSession = {
        ...session,
        title,
        description:
          input.description !== undefined
            ? (input.description?.trim() || null)
            : session.description,
        subject:
          input.subject !== undefined
            ? (input.subject?.trim() || null)
            : session.subject,
        startsAt,
        endsAt,
        joinOpensMinutesBefore,
        chatEnabled:
          input.chatEnabled !== undefined ? input.chatEnabled : session.chatEnabled,
        updatedAt: this.clock.now(),
      };

      const result = await this.sessionRepository.update(updatedSession);

      await this.auditService?.record({
        userId: user.id,
        action: 'session.updated',
        targetType: 'VideoSession',
        targetId: result.id,
        details: {
          classGroupId: result.classGroupId,
          title: result.title,
          startsAt: result.startsAt.toISOString(),
          endsAt: result.endsAt.toISOString(),
          status: result.status,
        },
      });

      try {
        await this.eventsPublisher?.publishToClass(result.classGroupId, {
          type: 'session.updated',
          sessionId: result.id,
          classGroupId: result.classGroupId,
          status: result.status,
          startsAt: result.startsAt.toISOString(),
          endsAt: result.endsAt.toISOString(),
          at: this.clock.now().toISOString(),
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
