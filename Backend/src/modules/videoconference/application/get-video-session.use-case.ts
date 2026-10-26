import type { VideoSessionRepositoryPort } from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import { NotFoundError, ForbiddenError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export class GetVideoSessionUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(user: UserContext, sessionId: string): Promise<VideoSessionDto> {
    try {
      const session = await this.sessionRepository.findById(sessionId);
      if (!session) {
        throw new NotFoundError('Video session not found');
      }

      if (user.role !== 'ADMIN' && session.hostId !== user.id) {
        const access = await this.classAccessPort.getClassAccess(user.id, session.classGroupId);
        if (!access.isMember && !access.isTeacherAssigned && !access.isReferent) {
          throw new ForbiddenError('Access denied to this video session');
        }
      }

      return toVideoSessionDto(session);
    } catch (err) {
      throw mapDomainErrorToAppError(err);
    }
  }
}
