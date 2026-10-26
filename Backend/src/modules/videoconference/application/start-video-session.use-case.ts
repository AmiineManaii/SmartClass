import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import type { RoomServicePort } from '../domain/room-service.port.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { canHost, canStart } from '../domain/video-session-policy.js';
import {
  SessionAccessDeniedDomainError,
  SessionStartTooEarlyDomainError,
} from '../domain/domain-errors.js';
import { NotFoundError, ConflictError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class StartVideoSessionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly clock: ClockPort,
    private readonly roomService?: RoomServicePort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<VideoSessionDto> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      // Idempotency: if already in progress, return immediately
      if (session.status === 'IN_PROGRESS') {
        return toVideoSessionDto(session);
      }

      if (session.status !== 'SCHEDULED') {
        throw new ConflictError(
          `Session cannot be started; current status is ${session.status}`,
        );
      }

      const isHost = session.hostId === user.id;
      const isAdmin = user.role === 'ADMIN';

      if (!isAdmin && !isHost) {
        throw new SessionAccessDeniedDomainError(
          'Only the host or admin can start this session',
        );
      }

      const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
      if (!isAdmin && !canHost(user, access)) {
        throw new SessionAccessDeniedDomainError(
          'User is not authorized to host sessions for this class',
        );
      }

      const now = this.clock.now();
      if (!canStart(user, session, access, now)) {
        throw new SessionStartTooEarlyDomainError(session.startsAt);
      }

      // Ensure LiveKit room exists
      if (this.roomService) {
        await this.roomService.createRoom(session.roomName, 10);
      }

      const updated = await this.sessionRepository.updateStatusAtomic(
        sessionId,
        'SCHEDULED',
        'IN_PROGRESS',
        { startedAt: now },
      );

      const finalSession = updated ?? (await this.sessionRepository.findById(sessionId));
      if (!finalSession || finalSession.status !== 'IN_PROGRESS') {
        throw new ConflictError('Failed to transition session to IN_PROGRESS');
      }

      await this.auditService?.record({
        userId: user.id,
        action: 'session.started',
        targetType: 'VideoSession',
        targetId: finalSession.id,
        details: {
          classGroupId: finalSession.classGroupId,
          title: finalSession.title,
          startedAt: now.toISOString(),
        },
      });

      try {
        await this.eventsPublisher?.publishToClass(finalSession.classGroupId, {
          type: 'session.started',
          sessionId: finalSession.id,
          classGroupId: finalSession.classGroupId,
          status: finalSession.status,
          startsAt: finalSession.startsAt.toISOString(),
          endsAt: finalSession.endsAt.toISOString(),
          at: now.toISOString(),
        });
      } catch {
        // Never fail request if SSE publish fails
      }

      return toVideoSessionDto(finalSession);
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
