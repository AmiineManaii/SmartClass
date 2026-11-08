import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { RoomServicePort } from '../domain/room-service.port.js';
import type { AuditServicePort } from '../../../shared/audit/audit.service.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { NotFoundError, ConflictError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';

export interface RecordingUserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class StartRecordingUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly roomService: RoomServicePort,
    private readonly auditService?: AuditServicePort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(user: RecordingUserContext, sessionId: string): Promise<VideoSessionDto> {
    const session = await this.sessionRepository.findById(sessionId);
    if (!session) throw new NotFoundError('Video session not found');
    if (session.status !== 'IN_PROGRESS') {
      throw new ConflictError(`Session must be live to record (status: ${session.status})`);
    }
    const isHost = session.hostId === user.id;
    const isAdmin = user.role === 'ADMIN';
    if (!isAdmin && !isHost) {
      throw new ConflictError('Only host or admin can start recording');
    }

    console.log('[StartRecordingUseCase] Requesting room recording for roomName:', session.roomName);
    let egressId: string;
    try {
      egressId = await this.roomService.startRecording(session.roomName);
      console.log('[StartRecordingUseCase] Successfully started egress:', egressId);
    } catch (err: any) {
      console.error('[StartRecordingUseCase] roomService.startRecording FAILED:', err?.message || err, err?.stack);
      throw err;
    }

    const updated = await this.sessionRepository.update({
      ...session,
      recordingEgressId: egressId,
    });

    await this.auditService?.record({
      userId: user.id,
      action: 'session.recording.started',
      targetType: 'VideoSession',
      targetId: session.id,
      details: { egressId },
    });

    try {
      await this.eventsPublisher?.publishToClass(updated.classGroupId, {
        type: 'session.recording.started',
        sessionId: updated.id,
        at: new Date().toISOString(),
      });
    } catch {
      // ignore
    }

    return toVideoSessionDto(updated);
  }
}