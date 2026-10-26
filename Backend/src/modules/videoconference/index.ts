export {
  createVideoconferenceModule,
  type VideoconferenceModule,
  type VideoconferenceModuleOptions,
} from './videoconference.module.js';

export type {
  TimetableDayView,
  TimetableEventView,
  TimetableKind,
  TimetableTeacher,
  TimetableWeek,
} from './domain/timetable.entity.js';

export type {
  TimetableRepositoryPort,
  TimetableSlotInput,
} from './domain/timetable-repository.port.js';

export {
  GetTimetableWeekUseCase,
  startOfWeekMonday,
  toISODate,
} from './application/get-timetable-week.use-case.js';

export type {
  VideoSession,
  VideoSessionStatus,
  SessionPhase,
  SessionParticipant,
  SessionChatMessage,
  SessionParticipantRemoval,
} from './domain/video-session.entity.js';

export {
  sessionPhase,
  transitionVideoSession,
  type TransitionMeta,
} from './domain/video-session-lifecycle.js';

export {
  validateSessionSchedule,
  validateSessionTitle,
  validateChatMessageContent,
} from './domain/video-session-validation.js';

export {
  canHost,
  canStart,
  evaluateJoinPermission,
  hasTimeOverlap,
} from './domain/video-session-policy.js';

export type {
  VideoSessionRepositoryPort,
  VideoSessionListFilter,
} from './domain/video-session-repository.port.js';

export type { SessionParticipantRepositoryPort } from './domain/session-participant-repository.port.js';
export type { SessionChatRepositoryPort } from './domain/session-chat-repository.port.js';
export type { SessionRemovalRepositoryPort } from './domain/session-removal-repository.port.js';
export type { ClassAccessPort } from './domain/class-access.port.js';
export type { ClockPort } from './domain/clock.port.js';
export type {
  RoomServicePort,
  JoinTokenPermissions,
  JoinTokenResult,
} from './domain/room-service.port.js';

export { PrismaVideoSessionRepositoryAdapter } from './infrastructure/prisma-video-session-repository.adapter.js';
export { PrismaSessionParticipantRepositoryAdapter } from './infrastructure/prisma-session-participant-repository.adapter.js';
export { PrismaSessionChatRepositoryAdapter } from './infrastructure/prisma-session-chat-repository.adapter.js';
export { PrismaSessionRemovalRepositoryAdapter } from './infrastructure/prisma-session-removal-repository.adapter.js';
export { PrismaClassAccessAdapter } from './infrastructure/prisma-class-access.adapter.js';
export { LiveKitRoomAdapter } from './infrastructure/livekit-room.adapter.js';
export { SystemClockAdapter } from './infrastructure/system-clock.adapter.js';

export {
  CreateVideoSessionUseCase,
  type CreateVideoSessionInput,
} from './application/create-video-session.use-case.js';

export {
  ListVideoSessionsUseCase,
  type ListVideoSessionsQuery,
  type ListVideoSessionsResult,
} from './application/list-video-sessions.use-case.js';

export { GetVideoSessionUseCase } from './application/get-video-session.use-case.js';

export {
  UpdateVideoSessionUseCase,
  type UpdateVideoSessionInput,
} from './application/update-video-session.use-case.js';

export {
  CancelVideoSessionUseCase,
  type CancelVideoSessionInput,
} from './application/cancel-video-session.use-case.js';

export { StartVideoSessionUseCase } from './application/start-video-session.use-case.js';
export {
  IssueJoinTokenUseCase,
  type JoinTokenDto,
} from './application/issue-join-token.use-case.js';
export { EndVideoSessionUseCase } from './application/end-video-session.use-case.js';
export { LeaveVideoSessionUseCase } from './application/leave-video-session.use-case.js';

export { MuteParticipantUseCase } from './application/mute-participant.use-case.js';
export { MuteAllUseCase } from './application/mute-all.use-case.js';
export { RemoveParticipantUseCase } from './application/remove-participant.use-case.js';

export {
  CreateSessionChatMessageUseCase,
  type CreateChatMessageInput,
} from './application/create-session-chat-message.use-case.js';
export {
  ListSessionChatMessagesUseCase,
  type ListChatMessagesQuery,
  type ListChatMessagesResult,
} from './application/list-session-chat-messages.use-case.js';

export { ReceiveLiveKitWebhookUseCase } from './application/receive-livekit-webhook.use-case.js';

export {
  type VideoSessionDto,
  toVideoSessionDto,
} from './application/video-session.dto.js';

export {
  type SessionChatMessageDto,
  toSessionChatMessageDto,
} from './application/session-chat.dto.js';

export type {
  LiveEventsPublisherPort,
  SessionEventPayload,
  SessionEventType,
} from './domain/live-events-publisher.port.js';

export {
  InMemoryLiveEventsHub,
  type SSEClientConnection,
} from './infrastructure/in-memory-live-events.hub.js';

export {
  GetMyNextSessionUseCase,
  type GetMyNextSessionCommand,
  type GetMyNextSessionResult,
} from './application/get-my-next-session.use-case.js';

