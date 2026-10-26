import type { VideoSessionStatus } from './video-session.entity.js';

export type SessionEventType =
  | 'session.created'
  | 'session.updated'
  | 'session.canceled'
  | 'session.started'
  | 'session.ended'
  | 'session.participant-joined'
  | 'session.participant-left'
  | 'session.participant-count-changed'
  | 'session.chat-message-created'
  | 'session.chat-settings-updated';

export interface SessionEventPayload {
  type: SessionEventType;
  sessionId: string;
  classGroupId: string;
  status?: VideoSessionStatus;
  startsAt?: string;
  endsAt?: string;
  at: string;
  data?: Record<string, unknown>;
}

export interface LiveEventsPublisherPort {
  publishToAudience(audienceUserIds: string[], event: SessionEventPayload): Promise<void>;
  publishToClass(classGroupId: string, event: SessionEventPayload): Promise<void>;
}
