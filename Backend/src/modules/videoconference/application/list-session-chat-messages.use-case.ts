import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { SessionChatRepositoryPort } from '../domain/session-chat-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/app-error.js';
import { toSessionChatMessageDto, type SessionChatMessageDto } from './session-chat.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export interface ListChatMessagesQuery {
  page?: number;
  limit?: number;
}

export interface ListChatMessagesResult {
  items: SessionChatMessageDto[];
  meta: {
    page: number;
    limit: number;
    total: number;
    totalPages: number;
    hasNextPage: boolean;
    hasPreviousPage: boolean;
  };
}

export class ListSessionChatMessagesUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly chatRepository: SessionChatRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(
    user: UserContext,
    sessionId: string,
    query: ListChatMessagesQuery,
  ): Promise<ListChatMessagesResult> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      if (user.role !== 'ADMIN' && session.hostId !== user.id) {
        const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
        if (!access.isMember && !access.isTeacherAssigned && !access.isReferent) {
          throw new ForbiddenError('Access denied to this session');
        }
      }

      const page = Math.max(1, query.page ?? 1);
      const limit = Math.min(100, Math.max(1, query.limit ?? 50));
      const offset = (page - 1) * limit;

      const { items, total } = await this.chatRepository.listBySession(sessionId, offset, limit);
      const totalPages = Math.ceil(total / limit);

      return {
        items: items.map(toSessionChatMessageDto),
        meta: {
          page,
          limit,
          total,
          totalPages,
          hasNextPage: page < totalPages,
          hasPreviousPage: page > 1,
        },
      };
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
