import express, { Router, type RequestHandler } from 'express';
import type { VideoconferenceController } from './videoconference.controller.js';
import type { RecordingController } from './recording.controller.js';
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
import {
  listRecordingsQuerySchema,
  subtitlesQuerySchema,
  mediaStreamQuerySchema,
  frameParamsSchema,
  stopRecordingBodySchema,
  uploadSourceDocBodySchema,
  updateLessonReviewBodySchema,
  regenerateSectionBodySchema,
  searchLessonQuerySchema,
  updateStudentProgressBodySchema,
  createBookmarkBodySchema,
  bookmarkIdParamsSchema,
  createStudentNoteBodySchema,
  updateStudentNoteBodySchema,
  noteIdParamsSchema,
  generateStudyArtifactBodySchema,
  submitQuizAttemptBodySchema,
  askLessonTutorBodySchema,
} from './recording.validation.js';

export interface VideoconferenceRouterOptions {
  controller: VideoconferenceController;
  recordingController?: RecordingController;
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
    recordingController,
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
    '/sessions/:id/recording/start',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema }),
    controller.startRecording,
  );

  router.post(
    '/sessions/:id/recording/stop',
    authenticateMiddleware,
    ...teacherMw,
    ...mutationMw,
    validate({ params: sessionIdParamsSchema }),
    controller.stopRecording,
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
    express.raw({ type: '*/*' }),
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

  // ───────────────────────────────────────────────────────────────────────────
  // LECTURE RECORDING, TEACHER REVIEW STUDIO, REPLAY & STUDENT AI LEARNING
  // ───────────────────────────────────────────────────────────────────────────
  if (recordingController) {
    router.get(
      '/recordings',
      authenticateMiddleware,
      validate({ query: listRecordingsQuerySchema }),
      recordingController.listRecordings,
    );

    router.get(
      '/ai-models',
      authenticateMiddleware,
      recordingController.getModelInventory,
    );

    router.post(
      '/sessions/:id/recording/start',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema }),
      recordingController.startRecording,
    );

    router.post(
      '/sessions/:id/recording/stop',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: stopRecordingBodySchema }),
      recordingController.stopRecording,
    );

    router.post(
      '/sessions/:id/recording/media',
      authenticateMiddleware,
      ...teacherMw,
      validate({ params: sessionIdParamsSchema }),
      recordingController.uploadRecordingMedia,
    );

    router.get(
      '/sessions/:id/recording',
      authenticateMiddleware,
      validate({ params: sessionIdParamsSchema }),
      recordingController.getRecording,
    );

    router.post(
      '/sessions/:id/recording/source-document',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: uploadSourceDocBodySchema }),
      recordingController.uploadSourceDocument,
    );

    router.post(
      '/sessions/:id/recording/retry',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema }),
      recordingController.retryProcessing,
    );

    router.delete(
      '/sessions/:id/recording',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema }),
      recordingController.deleteRecording,
    );

    // Media & Subtitles Streaming (HTTP Range 206 Partial Content supported)
    router.get(
      '/sessions/:id/recording/stream',
      authenticateMiddleware,
      validate({ params: sessionIdParamsSchema, query: mediaStreamQuerySchema }),
      recordingController.streamVideo,
    );

    router.get(
      '/sessions/:id/recording/poster',
      authenticateMiddleware,
      validate({ params: sessionIdParamsSchema, query: mediaStreamQuerySchema }),
      recordingController.streamPoster,
    );

    router.get(
      '/sessions/:id/recording/frames/:frameIndex',
      authenticateMiddleware,
      validate({ params: frameParamsSchema, query: mediaStreamQuerySchema }),
      recordingController.streamSlideFrame,
    );

    router.get(
      '/sessions/:id/recording/subtitles',
      authenticateMiddleware,
      validate({ params: sessionIdParamsSchema, query: subtitlesQuerySchema }),
      recordingController.streamSubtitles,
    );

    // Teacher Review & Publishing Studio
    router.get(
      '/sessions/:id/review',
      authenticateMiddleware,
      ...teacherMw,
      validate({ params: sessionIdParamsSchema }),
      recordingController.getTeacherReviewPackage,
    );

    router.patch(
      '/sessions/:id/review',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: updateLessonReviewBodySchema }),
      recordingController.updateTeacherReviewPackage,
    );

    router.post(
      '/sessions/:id/review/regenerate',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: regenerateSectionBodySchema }),
      recordingController.regenerateSection,
    );

    router.post(
      '/sessions/:id/review/approve',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema }),
      recordingController.approveLessonPackage,
    );

    router.post(
      '/sessions/:id/review/publish',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema }),
      recordingController.publishLessonPackage,
    );

    router.post(
      '/sessions/:id/review/unpublish',
      authenticateMiddleware,
      ...teacherMw,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema }),
      recordingController.unpublishLessonPackage,
    );

    // Student Lecture Learning Workspace, Smart Search, Study Lab & AI Tutor
    router.get(
      '/sessions/:id/workspace',
      authenticateMiddleware,
      validate({ params: sessionIdParamsSchema }),
      recordingController.getStudentWorkspace,
    );

    router.get(
      '/sessions/:id/workspace/search',
      authenticateMiddleware,
      validate({ params: sessionIdParamsSchema, query: searchLessonQuerySchema }),
      recordingController.searchLessonContent,
    );

    router.put(
      '/sessions/:id/workspace/progress',
      authenticateMiddleware,
      validate({ params: sessionIdParamsSchema, body: updateStudentProgressBodySchema }),
      recordingController.updateStudentProgress,
    );

    router.post(
      '/sessions/:id/workspace/bookmarks',
      authenticateMiddleware,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: createBookmarkBodySchema }),
      recordingController.createBookmark,
    );

    router.delete(
      '/sessions/:id/workspace/bookmarks/:bookmarkId',
      authenticateMiddleware,
      ...mutationMw,
      validate({ params: bookmarkIdParamsSchema }),
      recordingController.deleteBookmark,
    );

    router.post(
      '/sessions/:id/workspace/notes',
      authenticateMiddleware,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: createStudentNoteBodySchema }),
      recordingController.createStudentNote,
    );

    router.patch(
      '/sessions/:id/workspace/notes/:noteId',
      authenticateMiddleware,
      ...mutationMw,
      validate({ params: noteIdParamsSchema, body: updateStudentNoteBodySchema }),
      recordingController.updateStudentNote,
    );

    router.delete(
      '/sessions/:id/workspace/notes/:noteId',
      authenticateMiddleware,
      ...mutationMw,
      validate({ params: noteIdParamsSchema }),
      recordingController.deleteStudentNote,
    );

    router.post(
      '/sessions/:id/workspace/study-artifacts',
      authenticateMiddleware,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: generateStudyArtifactBodySchema }),
      recordingController.generateStudyArtifact,
    );

    router.post(
      '/sessions/:id/workspace/quiz-attempts',
      authenticateMiddleware,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: submitQuizAttemptBodySchema }),
      recordingController.submitQuizAttempt,
    );

    router.post(
      '/sessions/:id/workspace/tutor/ask',
      authenticateMiddleware,
      ...mutationMw,
      validate({ params: sessionIdParamsSchema, body: askLessonTutorBodySchema }),
      recordingController.askLessonAiTutor,
    );
  }

  return router;
};
