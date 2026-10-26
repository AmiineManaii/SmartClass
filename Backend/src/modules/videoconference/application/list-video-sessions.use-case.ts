import type {
  VideoSessionRepositoryPort,
  VideoSessionListFilter,
} from '../domain/video-session-repository.port.js';
import type { ClassAccessPort } from '../domain/class-access.port.js';
import type { VideoSessionStatus } from '../domain/video-session.entity.js';
import { ForbiddenError } from '../../../shared/errors/app-error.js';
import { toVideoSessionDto, type VideoSessionDto } from './video-session.dto.js';
import { mapDomainErrorToAppError } from './domain-error-mapper.js';

export interface ListVideoSessionsQuery {
  classGroupId?: string;
  status?: VideoSessionStatus;
  page?: number;
  limit?: number;
  scope?: 'all' | 'mine';
}

export interface UserContext {
  id: string;
  role: 'STUDENT' | 'TEACHER' | 'ADMIN';
}

export interface PaginationMeta {
  page: number;
  limit: number;
  total: number;
  totalPages: number;
  hasNextPage: boolean;
  hasPreviousPage: boolean;
}

export interface ListVideoSessionsResult {
  items: VideoSessionDto[];
  meta: PaginationMeta;
}

export class ListVideoSessionsUseCase {
  constructor(
    private readonly sessionRepository: VideoSessionRepositoryPort,
    private readonly classAccessPort: ClassAccessPort,
  ) {}

  public async execute(
    user: UserContext,
    query: ListVideoSessionsQuery,
  ): Promise<ListVideoSessionsResult> {
    try {
      const page = Math.max(1, query.page ?? 1);
      const limit = Math.min(100, Math.max(1, query.limit ?? 20));
      const offset = (page - 1) * limit;

      const filter: VideoSessionListFilter = {
        status: query.status,
        offset,
        limit,
      };

      if (user.role === 'ADMIN') {
        if (query.classGroupId) {
          filter.classGroupId = query.classGroupId;
        }
        if (query.scope === 'mine') {
          filter.hostId = user.id;
        }
      } else if (user.role === 'TEACHER') {
        if (query.scope === 'mine') {
          filter.hostId = user.id;
        }

        if (query.classGroupId) {
          const access = await this.classAccessPort.getClassAccess(user.id, query.classGroupId);
          if (!access.isTeacherAssigned && !access.isReferent && !access.isMember) {
            throw new ForbiddenError('Access denied to this class group');
          }
          filter.classGroupId = query.classGroupId;
        } else if (!filter.hostId) {
          const assignedClassIds = await this.classAccessPort.getUserClassGroupIds(user.id);
          if (assignedClassIds.length === 0) {
            return this.emptyResult(page, limit);
          }
          filter.classGroupIds = assignedClassIds;
        }
      } else {
        // STUDENT role
        const studentClassIds = await this.classAccessPort.getUserClassGroupIds(user.id);

        if (query.classGroupId) {
          if (!studentClassIds.includes(query.classGroupId)) {
            throw new ForbiddenError('Access denied to this class group');
          }
          filter.classGroupId = query.classGroupId;
        } else {
          if (studentClassIds.length === 0) {
            return this.emptyResult(page, limit);
          }
          filter.classGroupIds = studentClassIds;
        }
      }

      const { items, total } = await this.sessionRepository.list(filter);
      const totalPages = Math.ceil(total / limit);

      return {
        items: items.map(toVideoSessionDto),
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

  private emptyResult(page: number, limit: number): ListVideoSessionsResult {
    return {
      items: [],
      meta: {
        page,
        limit,
        total: 0,
        totalPages: 0,
        hasNextPage: false,
        hasPreviousPage: false,
      },
    };
  }
}
