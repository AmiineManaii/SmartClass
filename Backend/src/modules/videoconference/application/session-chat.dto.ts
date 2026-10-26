import type { SessionChatMessage } from '../domain/video-session.entity.js';

export interface SessionChatMessageDto {
  id: string;
  sessionId: string;
  senderId: string;
  clientMessageId: string;
  senderDisplayName: string;
  senderRole: string;
  content: string;
  createdAt: string;
}

export const toSessionChatMessageDto = (msg: SessionChatMessage): SessionChatMessageDto => ({
  id: msg.id,
  sessionId: msg.sessionId,
  senderId: msg.senderId,
  clientMessageId: msg.clientMessageId,
  senderDisplayName: msg.senderDisplayName,
  senderRole: msg.senderRole,
  content: msg.content,
  createdAt: msg.createdAt.toISOString(),
});
