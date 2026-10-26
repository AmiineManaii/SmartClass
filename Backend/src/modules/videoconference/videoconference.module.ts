import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  createRequireApprovedTeacherMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { TimetableRepositoryPort } from './domain/timetable-repository.port.js';
import type { VideoSessionRepositoryPort } from './domain/video-session-repository.port.js';
import type { SessionParticipantRepositoryPort } from './domain/session-participant-repository.port.js';
import type { SessionChatRepositoryPort } from './domain/session-chat-repository.port.js';
import type { SessionRemovalRepositoryPort } from './domain/session-removal-repository.port.js';
import type { ClassAccessPort } from './domain/class-access.port.js';
import type { ClockPort } from './domain/clock.port.js';
import type { AuditServicePort } from '../../shared/audit/audit.service.js';
import type { RoomServicePort } from './domain/room-service.port.js';
import type { GroupRepositoryPort } from '../groups/index.js';

import { PrismaTimetableRepositoryAdapter } from './infrastructure/prisma-timetable-repository.adapter.js';
import { PrismaVideoSessionRepositoryAdapter } from './infrastructure/prisma-video-session-repository.adapter.js';
import { PrismaSessionParticipantRepositoryAdapter } from './infrastructure/prisma-session-participant-repository.adapter.js';
import { PrismaSessionChatRepositoryAdapter } from './infrastructure/prisma-session-chat-repository.adapter.js';
import { PrismaSessionRemovalRepositoryAdapter } from './infrastructure/prisma-session-removal-repository.adapter.js';
import { PrismaClassAccessAdapter } from './infrastructure/prisma-class-access.adapter.js';
import { LiveKitRoomAdapter } from './infrastructure/livekit-room.adapter.js';
import { SystemClockAdapter } from './infrastructure/system-clock.adapter.js';
import { PrismaAuditService } from '../../shared/audit/audit.service.js';

import { GetTimetableWeekUseCase } from './application/get-timetable-week.use-case.js';
import { CreateVideoSessionUseCase } from './application/create-video-session.use-case.js';
import { ListVideoSessionsUseCase } from './application/list-video-sessions.use-case.js';
import { GetVideoSessionUseCase } from './application/get-video-session.use-case.js';
import { UpdateVideoSessionUseCase } from './application/update-video-session.use-case.js';
import { CancelVideoSessionUseCase } from './application/cancel-video-session.use-case.js';
import { StartVideoSessionUseCase } from './application/start-video-session.use-case.js';
import { IssueJoinTokenUseCase } from './application/issue-join-token.use-case.js';
import { EndVideoSessionUseCase } from './application/end-video-session.use-case.js';
import { LeaveVideoSessionUseCase } from './application/leave-video-session.use-case.js';
import { MuteParticipantUseCase } from './application/mute-participant.use-case.js';
import { MuteAllUseCase } from './application/mute-all.use-case.js';
import { RemoveParticipantUseCase } from './application/remove-participant.use-case.js';
import { CreateSessionChatMessageUseCase } from './application/create-session-chat-message.use-case.js';
import { ListSessionChatMessagesUseCase } from './application/list-session-chat-messages.use-case.js';
import { ListSessionParticipantsUseCase } from './application/list-session-participants.use-case.js';
import { SetSessionChatEnabledUseCase } from './application/set-session-chat-enabled.use-case.js';
import { ReceiveLiveKitWebhookUseCase } from './application/receive-livekit-webhook.use-case.js';
import { GetMyNextSessionUseCase } from './application/get-my-next-session.use-case.js';
import { InMemoryLiveEventsHub } from './infrastructure/in-memory-live-events.hub.js';

import { VideoconferenceController } from './presentation/videoconference.controller.js';
import { createVideoconferenceRouter } from './presentation/videoconference.routes.js';
import { createRateLimiter } from '../../shared/http/rate-limiter.js';

export interface VideoconferenceModuleOptions {
  timetableRepository?: TimetableRepositoryPort;
  sessionRepository?: VideoSessionRepositoryPort;
  participantRepository?: SessionParticipantRepositoryPort;
  chatRepository?: SessionChatRepositoryPort;
  removalRepository?: SessionRemovalRepositoryPort;
  classAccessPort?: ClassAccessPort;
  groupRepository?: GroupRepositoryPort;
  clock?: ClockPort;
  auditService?: AuditServicePort;
  roomService?: RoomServicePort;
  tokenService?: TokenServicePort;
  liveEventsHub?: InMemoryLiveEventsHub;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
  requireApprovedTeacherMiddleware?: RequestHandler;
  mutationRateLimiter?: RequestHandler;
  webhookRateLimiter?: RequestHandler;
  sseRateLimiter?: RequestHandler;
}

export interface VideoconferenceModule {
  router: Router;
  controller: VideoconferenceController;
  sessionRepository: VideoSessionRepositoryPort;
  participantRepository: SessionParticipantRepositoryPort;
  chatRepository: SessionChatRepositoryPort;
  removalRepository: SessionRemovalRepositoryPort;
  classAccessPort: ClassAccessPort;
  roomService: RoomServicePort;
  liveEventsHub: InMemoryLiveEventsHub;
}

export const createVideoconferenceModule = (
  options: VideoconferenceModuleOptions = {},
): VideoconferenceModule => {
  const timetableRepository = options.timetableRepository ?? new PrismaTimetableRepositoryAdapter();
  const sessionRepository = options.sessionRepository ?? new PrismaVideoSessionRepositoryAdapter();
  const participantRepository =
    options.participantRepository ?? new PrismaSessionParticipantRepositoryAdapter();
  const chatRepository = options.chatRepository ?? new PrismaSessionChatRepositoryAdapter();
  const removalRepository =
    options.removalRepository ?? new PrismaSessionRemovalRepositoryAdapter();
  const classAccessPort =
    options.classAccessPort ?? new PrismaClassAccessAdapter(options.groupRepository);
  const clock = options.clock ?? new SystemClockAdapter();
  const auditService = options.auditService ?? new PrismaAuditService();
  const roomService = options.roomService ?? new LiveKitRoomAdapter();
  const liveEventsHub = options.liveEventsHub ?? new InMemoryLiveEventsHub(classAccessPort);

  const getTimetableWeekUseCase = new GetTimetableWeekUseCase(timetableRepository);
  const createVideoSessionUseCase = new CreateVideoSessionUseCase(
    sessionRepository,
    classAccessPort,
    clock,
    auditService,
    roomService,
    liveEventsHub,
  );
  const listVideoSessionsUseCase = new ListVideoSessionsUseCase(sessionRepository, classAccessPort);
  const getVideoSessionUseCase = new GetVideoSessionUseCase(sessionRepository, classAccessPort);
  const updateVideoSessionUseCase = new UpdateVideoSessionUseCase(
    sessionRepository,
    classAccessPort,
    clock,
    auditService,
    liveEventsHub,
  );
  const cancelVideoSessionUseCase = new CancelVideoSessionUseCase(
    sessionRepository,
    classAccessPort,
    auditService,
    liveEventsHub,
  );

  const startVideoSessionUseCase = new StartVideoSessionUseCase(
    sessionRepository,
    classAccessPort,
    clock,
    roomService,
    auditService,
    liveEventsHub,
  );

  const issueJoinTokenUseCase = new IssueJoinTokenUseCase(
    sessionRepository,
    removalRepository,
    participantRepository,
    classAccessPort,
    roomService,
    clock,
    auditService,
    liveEventsHub,
  );

  const endVideoSessionUseCase = new EndVideoSessionUseCase(
    sessionRepository,
    participantRepository,
    clock,
    roomService,
    auditService,
    liveEventsHub,
  );

  const leaveVideoSessionUseCase = new LeaveVideoSessionUseCase(
    sessionRepository,
    participantRepository,
    clock,
    liveEventsHub,
  );

  const muteParticipantUseCase = new MuteParticipantUseCase(sessionRepository, roomService);
  const muteAllUseCase = new MuteAllUseCase(sessionRepository, roomService);
  const removeParticipantUseCase = new RemoveParticipantUseCase(
    sessionRepository,
    removalRepository,
    participantRepository,
    clock,
    roomService,
    auditService,
  );

  const createSessionChatMessageUseCase = new CreateSessionChatMessageUseCase(
    sessionRepository,
    chatRepository,
    removalRepository,
    classAccessPort,
    liveEventsHub,
  );

  const listSessionChatMessagesUseCase = new ListSessionChatMessagesUseCase(
    sessionRepository,
    chatRepository,
    classAccessPort,
  );

  const listSessionParticipantsUseCase = new ListSessionParticipantsUseCase(
    sessionRepository,
    participantRepository,
  );

  const setSessionChatEnabledUseCase = new SetSessionChatEnabledUseCase(
    sessionRepository,
    clock,
    auditService,
    liveEventsHub,
  );

  const receiveLiveKitWebhookUseCase = new ReceiveLiveKitWebhookUseCase(
    sessionRepository,
    participantRepository,
    undefined,
    liveEventsHub,
  );

  const getMyNextSessionUseCase = new GetMyNextSessionUseCase(
    sessionRepository,
    classAccessPort,
    clock,
    roomService,
    participantRepository,
  );

  const controller = new VideoconferenceController(
    getTimetableWeekUseCase,
    createVideoSessionUseCase,
    listVideoSessionsUseCase,
    getVideoSessionUseCase,
    updateVideoSessionUseCase,
    cancelVideoSessionUseCase,
    startVideoSessionUseCase,
    issueJoinTokenUseCase,
    endVideoSessionUseCase,
    leaveVideoSessionUseCase,
    muteParticipantUseCase,
    muteAllUseCase,
    removeParticipantUseCase,
    createSessionChatMessageUseCase,
    listSessionChatMessagesUseCase,
    listSessionParticipantsUseCase,
    setSessionChatEnabledUseCase,
    receiveLiveKitWebhookUseCase,
    getMyNextSessionUseCase,
    liveEventsHub,
  );

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('VideoconferenceModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireAdminMiddleware =
    options.requireAdminMiddleware ?? createRequireRoleMiddleware(['ADMIN'] as Role[]);

  const requireApprovedTeacherMiddleware =
    options.requireApprovedTeacherMiddleware ??
    createRequireApprovedTeacherMiddleware(['TEACHER', 'ADMIN'] as Role[]);

  const mutationRateLimiter =
    options.mutationRateLimiter ?? createRateLimiter({ windowMs: 60000, limit: 20 });

  const webhookRateLimiter =
    options.webhookRateLimiter ?? createRateLimiter({ windowMs: 60000, limit: 120 });

  const sseRateLimiter =
    options.sseRateLimiter ?? createRateLimiter({ windowMs: 60000, limit: 60 });

  const router = createVideoconferenceRouter({
    controller,
    authenticateMiddleware,
    requireAdminMiddleware,
    requireApprovedTeacherMiddleware,
    mutationRateLimiter,
    webhookRateLimiter,
    sseRateLimiter,
  });

  return {
    router,
    controller,
    sessionRepository,
    participantRepository,
    chatRepository,
    removalRepository,
    classAccessPort,
    roomService,
    liveEventsHub,
  };
};
