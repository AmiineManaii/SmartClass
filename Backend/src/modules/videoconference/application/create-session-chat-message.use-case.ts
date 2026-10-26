import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { SessionChatRepositoryPort } from '../domain/session-chat-repository.port.js';
import type { SessionRemovalRepositoryPort } from '../domain/session-removal-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { LiveEventsPublisherPort } from '../domain/live-events-publisher.port.js';
import { validateChatMessageContent } from '../domain/video-session-validation.js';
import {
  NotFoundError,
  ForbiddenError,
  ConflictError,
} from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import { toSessionChatMessageDto, type SessionChatMessageDto } from './session-chat.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

import { randomUUID } from 'node:crypto';

export interface UserContextWithProfile {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
  firstName?: string | null;
  lastName?: string | null;
}

export interface CreateChatMessageInput {
  clientMessageId?: string;
  content: string;
}

export class CreateSessionChatMessageUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly chatRepository: SessionChatRepositoryPort,
    private readonly removalRepository: SessionRemovalRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
    private readonly eventsPublisher?: LiveEventsPublisherPort,
  ) {}

  public async execute(
    user: UserContextWithProfile,
    sessionId: string,
    input: CreateChatMessageInput,
  ): Promise<SessionChatMessageDto> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      if (session.status !== 'IN_PROGRESS') {
        throw new ConflictError(
          'Chat is only available while the live session is in progress',
          ErrorCodes.CONFLICT,
        );
      }

      if (!session.chatEnabled) {
        throw new ConflictError(
          'Chat is disabled for this live session',
          ErrorCodes.CHAT_DISABLED,
        );
      }

      const isRemoved = await this.removalRepository.isUserRemoved(sessionId, user.id);
      if (isRemoved) {
        throw new ForbiddenError(
          'You have been removed from this live session and cannot post messages',
        );
      }

      if (user.role !== 'ADMIN' && session.hostId !== user.id) {
        const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
        if (!access.isMember && !access.isTeacherAssigned && !access.isReferent) {
          throw new ForbiddenError('Access denied to this session');
        }
      }

      const content = validateChatMessageContent(input.content);
      const clientMessageId = input.clientMessageId ?? randomUUID();

      // Idempotency: check by clientMessageId
      const existing = await this.chatRepository.findByClientMessageId(
        sessionId,
        user.id,
        clientMessageId,
      );
      if (existing) {
        return toSessionChatMessageDto(existing);
      }

      const displayName =
        user.firstName && user.lastName
          ? `${user.firstName} ${user.lastName}`
          : user.role === 'ADMIN'
            ? 'Administrateur'
            : user.role === 'TEACHER'
              ? 'Enseignant'
              : 'Élève';

      const created = await this.chatRepository.createMessage({
        sessionId,
        senderId: user.id,
        clientMessageId,
        senderDisplayName: displayName,
        senderRole: user.role,
        content,
      });

      const messageDto = toSessionChatMessageDto(created);

      try {
        await this.eventsPublisher?.publishToClass(session.classGroupId, {
          type: 'session.chat-message-created',
          sessionId,
          classGroupId: session.classGroupId,
          status: session.status,
          at: created.createdAt.toISOString(),
          data: {
            message: messageDto,
          },
        });
      } catch {
        // Never fail request if SSE publish fails
      }

      return messageDto;
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
