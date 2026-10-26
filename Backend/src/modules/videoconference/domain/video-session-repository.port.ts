import type { VideoSession, VideoSessionStatus } from './video-session.entity.js';

export interface VideoSessionListFilter {
  classGroupId?: string;
  classGroupIds?: string[];
  hostId?: string;
  status?: VideoSessionStatus;
  offset: number;
  limit: number;
}

export interface VideoSessionRepositoryPort {
  create(session: VideoSession): Promise<VideoSession>;
  findById(id: string): Promise<VideoSession | null>;
  findByRoomName(roomName: string): Promise<VideoSession | null>;
  update(session: VideoSession): Promise<VideoSession>;
  updateStatusAtomic(
    id: string,
    expectedStatus: VideoSessionStatus,
    newStatus: VideoSessionStatus,
    meta?: { startedAt?: Date; endedAt?: Date; cancelReason?: string },
  ): Promise<VideoSession | null>;
  findOverlappingForClass(
    classGroupId: string,
    startsAt: Date,
    endsAt: Date,
    excludeSessionId?: string,
  ): Promise<VideoSession[]>;
  findActiveForHost(hostId: string, excludeSessionId?: string): Promise<VideoSession | null>;
  findUpcomingOrLiveForClass(
    classGroupId: string,
    now: Date,
  ): Promise<{ live: VideoSession | null; upcoming: VideoSession | null }>;
  findUpcomingOrLiveForClasses(
    classGroupIds: string[],
    now: Date,
    horizonHours?: number,
  ): Promise<{ live: VideoSession | null; upcoming: VideoSession | null }>;
  list(filter: VideoSessionListFilter): Promise<{ items: VideoSession[]; total: number }>;
}
