import { Router, type RequestHandler } from 'express';
import type { VideoconferenceController } from './videoconference.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  timetableQuerySchema,
  createVideoSessionBodySchema,
  updateVideoSessionBodySchema,
  cancelVideoSessionBodySchema,
  listVideoSessionsQuerySchema,
  sessionIdParamsSchema,
  participantIdParamsSchema,
  removeParticipantBodySchema,
  createChatMessageBodySchema,
  listChatMessagesQuerySchema,
  chatSettingsBodySchema,
  nextSessionQuerySchema,
  sseEventsQuerySchema,
} from './videoconference.validation.js';

export interface VideoconferenceRouterOptions {
  controller: VideoconferenceController;
  authenticateMiddleware: RequestHandler;
  requireAdminMiddleware: RequestHandler;
  requireApprovedTeacherMiddleware?: RequestHandler;
  mutationRateLimiter?: RequestHandler;
  webhookRateLimiter?: RequestHandler;
  sseRateLimiter?: RequestHandler;
}

export const createVideoconferenceRouter = (options: VideoconferenceRouterOptions): Router => {
  const router = Router();
  const {
    controller,
    authenticateMiddleware,
    requireApprovedTeacherMiddleware,
    mutationRateLimiter,
    webhookRateLimiter,
    sseRateLimiter,
  } = options;

  const mutationMw = mutationRateLimiter ? [mutationRateLimiter] : [];
  const teacherMw = requireApprovedTeacherMiddleware ? [requireApprovedTeacherMiddleware] : [];
  const webhookMw = webhookRateLimiter ? [webhookRateLimiter] : [];
  const sseMw = sseRateLimiter ? [sseRateLimiter] : [];

  // Weekly timetable (class-scoped read)
  router.get(
    '/timetable',
    authenticateMiddleware,
    validate({ query: timetableQuerySchema }),
    controller.getTimetable,
  );

  // Live session CRUD & scheduling
  router.post(
    '/sessions',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ body: createVideoSessionBodySchema }),
    controller.createSession,
  );

  router.get(
    '/sessions',
    authenticateMiddleware,
    validate({ query: listVideoSessionsQuerySchema }),
    controller.listSessions,
  );

  router.get(
    '/sessions/:id',
    authenticateMiddleware,
    validate({ params: sessionIdParamsSchema }),
    controller.getSession,
  );

  router.patch(
    '/sessions/:id',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema, body: updateVideoSessionBodySchema }),
    controller.updateSession,
  );

  router.post(
    '/sessions/:id/cancel',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema, body: cancelVideoSessionBodySchema }),
    controller.cancelSession,
  );

  // LiveKit WebRTC Session Lifecycle
  router.post(
    '/sessions/:id/start',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema }),
    controller.startSession,
  );

  router.post(
    '/sessions/:id/join-token',
    authenticateMiddleware,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema }),
    controller.issueJoinToken,
  );

  router.post(
    '/sessions/:id/end',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema }),
    controller.endSession,
  );

  router.post(
    '/sessions/:id/leave',
    authenticateMiddleware,
    validate({ params: sessionIdParamsSchema }),
    controller.leaveSession,
  );

  // Participants & Attendance
  router.get(
    '/sessions/:id/participants',
    authenticateMiddleware,
    ...teacherMw,
    validate({ params: sessionIdParamsSchema }),
    controller.listParticipants,
  );

  // Moderation Controls (host/admin only)
  router.post(
    '/sessions/:id/participants/:userId/mute',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: participantIdParamsSchema }),
    controller.muteParticipant,
  );

  router.post(
    '/sessions/:id/participants/:userId/remove',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: participantIdParamsSchema, body: removeParticipantBodySchema }),
    controller.removeParticipant,
  );

  router.post(
    '/sessions/:id/mute-all',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema }),
    controller.muteAll,
  );

  // In-call Persistent Chat (supports both /messages and /chat/messages)
  router.get(
    '/sessions/:id/messages',
    authenticateMiddleware,
    validate({ params: sessionIdParamsSchema, query: listChatMessagesQuerySchema }),
    controller.listChatMessages,
  );
  router.get(
    '/sessions/:id/chat/messages',
    authenticateMiddleware,
    validate({ params: sessionIdParamsSchema, query: listChatMessagesQuerySchema }),
    controller.listChatMessages,
  );

  router.post(
    '/sessions/:id/messages',
    authenticateMiddleware,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema, body: createChatMessageBodySchema }),
    controller.createChatMessage,
  );
  router.post(
    '/sessions/:id/chat/messages',
    authenticateMiddleware,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema, body: createChatMessageBodySchema }),
    controller.createChatMessage,
  );

  // Chat Settings (supports both /chat-settings and /chat/settings)
  router.patch(
    '/sessions/:id/chat-settings',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema, body: chatSettingsBodySchema }),
    controller.setChatSettings,
  );
  router.patch(
    '/sessions/:id/chat/settings',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema, body: chatSettingsBodySchema }),
    controller.setChatSettings,
  );

  // LiveKit Webhook Handler (signature verified via JWT header in use case)
  router.post(
    '/webhooks/livekit',
    ...webhookMw,
    controller.receiveWebhook,
  );

  // Dashboard Next Session Feed
  router.get(
    '/me/next-session',
    authenticateMiddleware,
    validate({ query: nextSessionQuerySchema }),
    controller.getMyNextSession,
  );

  // Realtime Server-Sent Events (SSE)
  router.get(
    '/events',
    authenticateMiddleware,
    ...sseMw,
    validate({ query: sseEventsQuerySchema }),
    controller.streamEvents,
  );

  return router;
};
