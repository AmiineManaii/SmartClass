import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { ClockPort } from '../domain/clock.port.js';
import type { RoomServicePort } from '../domain/room-service.port.js';
import type { SessionParticipantRepositoryPort } from '../domain/session-participant-repository.port.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';

export interface GetMyNextSessionCommand {
  userId: string;
  role: string;
  horizonHours?: number;
}

export interface GetMyNextSessionResult {
  liveSession: VideoSessionDto | null;
  upcomingSession: VideoSessionDto | null;
  serverNow: string;
}

export class GetMyNextSessionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccess: ClassAccessPort,
    private readonly clock: ClockPort,
    private readonly roomService?: RoomServicePort,
    private readonly participantRepository?: SessionParticipantRepositoryPort,
  ) {}

  public async execute(command: GetMyNextSessionCommand): Promise<GetMyNextSessionResult> {
    const now = this.clock.now();
    const horizon = Math.min(Math.max(command.horizonHours ?? 24, 1), 72);

    let classGroupIds: string[] = [];

    if (command.role !== 'ADMIN') {
      classGroupIds = await this.classAccess.getUserClassGroupIds(command.userId);
      if (classGroupIds.length === 0) {
        return {
          liveSession: null,
          upcomingSession: null,
          serverNow: now.toISOString(),
        };
      }
    }

    const { live, upcoming } = await this.sessionRepository.findUpcomingOrLiveForClasses(
      classGroupIds,
      now,
      horizon,
    );

    let liveParticipantCount = 0;
    if (live) {
      if (this.roomService?.getParticipantCount) {
        liveParticipantCount = await this.roomService.getParticipantCount(live.roomName);
      }
      if (liveParticipantCount === 0 && this.participantRepository) {
        liveParticipantCount = await this.participantRepository.countActiveBySession(live.id);
      }
    }

    return {
      liveSession: live ? toVideoSessionDto(live, liveParticipantCount) : null,
      upcomingSession: upcoming ? toVideoSessionDto(upcoming, 0) : null,
      serverNow: now.toISOString(),
    };
  }
}
