import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { RoomServicePort } from '../domain/room-service.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { NotFoundError, ConflictError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';

export interface StopRecordingUserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class StopRecordingUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly roomService: RoomServicePort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(user: StopRecordingUserContext, sessionId: string): Promise<VideoSessionDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) throw new NotFoundError('Video session not found');
    if (!session.recordingEgressId) {
      throw new ConflictError('No active recording for this session');
    }
    const isHost = session.hostId === user.id;
    const isAdmin = user.role === 'ADMIN';
    if (!isAdmin && !isHost) {
      throw new ConflictError('Only host or admin can stop recording');
    }

    await this.roomService.stopRecording(session.recordingEgressId);

    const updated = await this.sessionRepository.update({
      ...session,
      recordingEgressId: null,
    });

    await this.auditService?.record({
      userId: user.id,
      action: 'session.recording.stopped',
      targetType: 'VideoSession',
      targetId: session.id,
      details: {},
    });

    try {
      await this.eventsPublisher?.publishToClass(updated.classGroupId, {
        type: 'session.recording.stopped',
        sessionId: updated.id,
        at: new Date().toISOString(),
      });
    } catch {
      // ignore
    }

    return toVideoSessionDto(updated);
  }
}