import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { SessionParticipantRepositoryPort } from '../domain/session-participant-repository.port.js';
import type { RoomServicePort } from '../domain/room-service.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { transitionVideoSession } from '../domain/video-session-lifecycle.js';
import { SessionAccessDeniedDomainError } from '../domain/domain-errors.js';
import { NotFoundError, ConflictError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class EndVideoSessionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly participantRepository: SessionParticipantRepositoryPort,
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

      // Idempotency: if already completed, return immediately
      if (session.status === 'COMPLETED') {
        return toVideoSessionDto(session);
      }

      if (session.status !== 'IN_PROGRESS') {
        throw new ConflictError(
          `Only in-progress sessions can be ended; current status is ${session.status}`,
        );
      }

      const isHost = session.hostId === user.id;
      const isAdmin = user.role === 'ADMIN';

      if (!isAdmin && !isHost) {
        throw new SessionAccessDeniedDomainError(
          'Only the host or admin can end this session',
        );
      }

      const now = this.clock.now();

      // Pure domain transition check
      transitionVideoSession(session, 'COMPLETED', { endedAt: now });

      const updated = await this.sessionRepository.updateStatusAtomic(
        sessionId,
        'IN_PROGRESS',
        'COMPLETED',
        { endedAt: now },
      );

      const finalSession = updated ?? (await this.sessionRepository.findById(sessionId));
      if (!finalSession) {
        throw new ConflictError('Failed to transition session to COMPLETED');
      }

      // Close LiveKit room
      if (this.roomService) {
        await this.roomService.closeRoom(session.roomName);
      }

      // Close open intervals for remaining participants
      const participants = await this.participantRepository.listBySession(sessionId);
      for (const p of participants) {
        if (!p.leftAt) {
          await this.participantRepository.recordLeave(sessionId, p.userId, now);
        }
      }

      await this.auditService?.record({
        userId: user.id,
        action: 'session.ended',
        targetType: 'VideoSession',
        targetId: finalSession.id,
        details: {
          classGroupId: finalSession.classGroupId,
          title: finalSession.title,
          endedAt: now.toISOString(),
        },
      });

      try {
        await this.eventsPublisher?.publishToClass(finalSession.classGroupId, {
          type: 'session.ended',
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
