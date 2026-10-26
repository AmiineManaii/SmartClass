import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { SessionRemovalRepositoryPort } from '../domain/session-removal-repository.port.js';
import type { SessionParticipantRepositoryPort } from '../domain/session-participant-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { RoomServicePort, JoinTokenPermissions } from '../domain/room-service.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import { evaluateJoinPermission } from '../domain/video-session-policy.js';
import {
  NotFoundError,
  ForbiddenError,
  ConflictError,
  ServiceUnavailableError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContextWithProfile {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
  firstName?: string | null;
  lastName?: string | null;
}

export interface JoinTokenDto {
  token: string;
  url: string;
  expiresAt: string;
  role: 'host' | 'student' | 'admin';
  permissions: JoinTokenPermissions;
}

export class IssueJoinTokenUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly removalRepository: SessionRemovalRepositoryPort,
    private readonly participantRepository: SessionParticipantRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly roomService?: RoomServicePort,
    private readonly clock?: ClockPort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(
    user: UserContextWithProfile,
    sessionId: string,
  ): Promise<JoinTokenDto> {
    try {
      if (!this.roomService) {
        throw new ServiceUnavailableError('Live service is not configured');
      }

      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      const isRemoved = await this.removalRepository.isUserRemoved(sessionId, user.id);
      const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
      const now = this.clock ? this.clock.now() : new Date();

      const evaluation = evaluateJoinPermission(user, session, access, isRemoved, now);
      if (!evaluation.allowed) {
        if (evaluation.reason === 'BANNED') {
          throw new ForbiddenError(
            'You have been removed from this live session and cannot rejoin',
          );
        }
        if (evaluation.reason === 'NOT_A_MEMBER') {
          throw new ForbiddenError('You are not enrolled in or assigned to this class');
        }
        if (evaluation.reason === 'NOT_STARTED') {
          throw new ConflictError(
            'The live session has not started yet',
            ErrorCodes.SESSION_NOT_JOINABLE,
          );
        }
        if (evaluation.reason === 'ENDED' || evaluation.reason === 'CANCELED') {
          throw new ConflictError('This live session has already ended or was canceled');
        }
      }

      // Reconnection & empty room recovery (ADR-0008): idempotently ensure room exists in LiveKit
      await this.roomService.createRoom(session.roomName, 10);

      const isHost = session.hostId === user.id;
      const isAdmin = user.role === 'ADMIN';

      const displayName =
        user.firstName && user.lastName
          ? `${user.firstName} ${user.lastName}`
          : isAdmin
            ? 'Administrateur'
            : isHost
              ? 'Enseignant'
              : 'Élève';

      const tokenResult = await this.roomService.issueJoinToken({
        roomName: session.roomName,
        identity: user.id,
        name: displayName,
        isHost,
        isAdmin,
        ttlSeconds: 3600,
      });

      // Record attendance interval
      await this.participantRepository.recordJoin(sessionId, user.id, now);

      try {
        await this.eventsPublisher?.publishToClass(session.classGroupId, {
          type: 'session.participant-joined',
          sessionId: session.id,
          classGroupId: session.classGroupId,
          status: session.status,
          at: now.toISOString(),
          data: { userId: user.id },
        });
      } catch {
        // Best-effort realtime publish
      }

      await this.auditService?.record({
        userId: user.id,
        action: 'participant.joined',
        targetType: 'VideoSession',
        targetId: session.id,
        details: {
          classGroupId: session.classGroupId,
          role: tokenResult.role,
        },
      });

      return {
        token: tokenResult.token,
        url: tokenResult.url,
        expiresAt: tokenResult.expiresAt.toISOString(),
        role: tokenResult.role,
        permissions: tokenResult.permissions,
      };
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
