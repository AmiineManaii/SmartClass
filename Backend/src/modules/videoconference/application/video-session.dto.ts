import type { VideoSession, VideoSessionStatus } from '../domain/video-session.entity.js';

export interface VideoSessionRecordingSummaryDto {
  status: string;
  hasVideo: boolean;
  hasLessonPackage: boolean;
  errorCode: string | null;
  errorMessage: string | null;
  jobStatus: string | null;
  jobStage: string | null;
  jobProgress: number | null;
  jobStartedAt: string | null;
}

export interface VideoSessionDto {
  id: string;
  classGroupId: string;
  hostId: string | null;
  hostName: string | null;
  subject: string | null;
  title: string;
  description: string | null;
  startsAt: string;
  endsAt: string;
  startedAt: string | null;
  endedAt: string | null;
  status: VideoSessionStatus;
  joinOpensMinutesBefore: number;
  chatEnabled: boolean;
  timetableSlotId: string | null;
  courseId: string | null;
  cancelReason: string | null;
  recordingSummary: VideoSessionRecordingSummaryDto | null;
  createdAt: string;
  updatedAt: string;
  participantCount?: number;
}

export const toVideoSessionDto = (
  session: VideoSession,
  participantCount?: number,
): VideoSessionDto => ({
  id: session.id,
  classGroupId: session.classGroupId,
  hostId: session.hostId,
  hostName: session.hostName ?? null,
  subject: session.subject ?? null,
  title: session.title,
  description: session.description ?? null,
  startsAt: session.startsAt.toISOString(),
  endsAt: session.endsAt.toISOString(),
  startedAt: session.startedAt ? session.startedAt.toISOString() : null,
  endedAt: session.endedAt ? session.endedAt.toISOString() : null,
  status: session.status,
  joinOpensMinutesBefore: session.joinOpensMinutesBefore,
  chatEnabled: session.chatEnabled,
  timetableSlotId: session.timetableSlotId ?? null,
  courseId: session.courseId ?? null,
  cancelReason: session.cancelReason ?? null,
  recordingSummary: session.recordingSummary
    ? {
        status: session.recordingSummary.status,
        hasVideo: session.recordingSummary.hasVideo,
        hasLessonPackage: session.recordingSummary.hasLessonPackage,
        errorCode: session.recordingSummary.errorCode,
        errorMessage: session.recordingSummary.errorMessage,
        jobStatus: session.recordingSummary.jobStatus,
        jobStage: session.recordingSummary.jobStage,
        jobProgress: session.recordingSummary.jobProgress,
        jobStartedAt: session.recordingSummary.jobStartedAt
          ? session.recordingSummary.jobStartedAt.toISOString()
          : null,
      }
    : null,
  createdAt: session.createdAt.toISOString(),
  updatedAt: session.updatedAt.toISOString(),
  participantCount: participantCount ?? 0,
});
