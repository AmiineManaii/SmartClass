import type { SessionChatMessage } from './video-session.entity.js';

export interface SessionChatRepositoryPort {
  createMessage(message: Omit<SessionChatMessage, 'id' | 'createdAt'>): Promise<SessionChatMessage>;
  findByClientMessageId(
    sessionId: string,
    senderId: string,
    clientMessageId: string,
  ): Promise<SessionChatMessage | null>;
  listBySession(
    sessionId: string,
    offset: number,
    limit: number,
  ): Promise<{ items: SessionChatMessage[]; total: number }>;
}
