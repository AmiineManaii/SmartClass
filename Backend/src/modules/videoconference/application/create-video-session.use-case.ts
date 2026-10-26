import { randomUUID } from 'node:crypto';
import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import type { RoomServicePort } from '../domain/room-service.port.js';
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
import { mapDomainErrorToAppError } from './domain-error-mapper.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';

export interface CreateVideoSessionInput {
  classGroupId: string;
  title: string;
  description?: string | null;
  subject?: string | null;
  mode: 'NOW' | 'SCHEDULED';
  startsAt?: string;
  endsAt?: string;
  durationMinutes?: number;
  joinOpensMinutesBefore?: number;
  chatEnabled?: boolean;
  timetableSlotId?: string | null;
  courseId?: string | null;
}

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class CreateVideoSessionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly clock: ClockPort,
    private readonly auditService?: AuditServicePort,
    private readonly roomService?: RoomServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(
    user: UserContext,
    input: CreateVideoSessionInput,
  ): Promise<VideoSessionDto> {
    try {
      const access = await this.classAccessPort.getClassAccess(user.id, input.classGroupId);
      if (!canHost(user, access)) {
        throw new SessionAccessDeniedDomainError(
          'User is not authorized to create live sessions for this class',
        );
      }

      const title = validateSessionTitle(input.title);
      const now = this.clock.now();

      let startsAt: Date;
      let isStartNow = false;

      if (input.mode === 'NOW') {
        startsAt = now;
        isStartNow = true;

        const activeForHost = await this.sessionRepository.findActiveForHost(user.id);
        if (activeForHost) {
          throw new SessionConflictDomainError('Host already has an active live session in progress');
        }
      } else {
        if (!input.startsAt) {
          throw new SessionValidationDomainError(
            'startsAt is required for scheduled sessions',
            'startsAt',
          );
        }
        startsAt = new Date(input.startsAt);
        if (Number.isNaN(startsAt.getTime())) {
          throw new SessionValidationDomainError('Invalid startsAt timestamp', 'startsAt');
        }
      }

      const computedDuration = input.durationMinutes ??
        (input.endsAt
          ? Math.max(5, Math.round((new Date(input.endsAt).getTime() - startsAt.getTime()) / 60000))
          : 60);

      const schedule = validateSessionSchedule({
        startsAt,
        durationMinutes: computedDuration,
        joinOpensMinutesBefore: input.joinOpensMinutesBefore ?? 5,
        now,
        isStartNow,
      });

      const overlapping = await this.sessionRepository.findOverlappingForClass(
        input.classGroupId,
        schedule.startsAt,
        schedule.endsAt,
      );
      if (overlapping.length > 0) {
        throw new SessionConflictDomainError(
          'A session is already scheduled or in progress for this class during this time interval',
        );
      }

      const id = randomUUID();
      const roomName = `room-${randomUUID()}`;

      if (input.mode === 'NOW' && this.roomService) {
        await this.roomService.createRoom(roomName, 10);
      }

      const session: VideoSession = {
        id,
        classGroupId: input.classGroupId,
        hostId: user.id,
        subject: input.subject?.trim() || null,
        title,
        description: input.description?.trim() || null,
        startsAt: schedule.startsAt,
        endsAt: schedule.endsAt,
        startedAt: input.mode === 'NOW' ? schedule.startsAt : null,
        endedAt: null,
        status: input.mode === 'NOW' ? 'IN_PROGRESS' : 'SCHEDULED',
        roomName,
        joinOpensMinutesBefore: schedule.joinOpensMinutesBefore,
        chatEnabled: input.chatEnabled !== undefined ? input.chatEnabled : true,
        timetableSlotId: input.timetableSlotId || null,
        courseId: input.courseId || null,
        cancelReason: null,
        createdAt: now,
        updatedAt: now,
      };

      const created = await this.sessionRepository.create(session);

      await this.auditService?.record({
        userId: user.id,
        action: 'session.created',
        targetType: 'VideoSession',
        targetId: created.id,
        details: {
          classGroupId: created.classGroupId,
          title: created.title,
          mode: input.mode,
          startsAt: created.startsAt.toISOString(),
          endsAt: created.endsAt.toISOString(),
          status: created.status,
        },
      });

      try {
        await this.eventsPublisher?.publishToClass(created.classGroupId, {
          type: 'session.created',
          sessionId: created.id,
          classGroupId: created.classGroupId,
          status: created.status,
          startsAt: created.startsAt.toISOString(),
          endsAt: created.endsAt.toISOString(),
          at: now.toISOString(),
        });
      } catch {
        // Never fail request if SSE publish fails
      }

      return toVideoSessionDto(created);
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
