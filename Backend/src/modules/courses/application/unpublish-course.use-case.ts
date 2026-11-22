import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { KnowledgeIndexerPort } from '../../knowledge/domain/knowledge-indexer.port.js';

export interface UnpublishCourseDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
}

/** Returns a published course to DRAFT (author or admin). */
export class UnpublishCourseUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly knowledgeIndexer?: KnowledgeIndexerPort,
  ) {}

  public async execute(dto: UnpublishCourseDTO): Promise<CourseDetail> {
    const course = await this.courses.findById(dto.courseId);
    if (!course) {
      throw new NotFoundError('Course not found');
    }
    if (course.authorId !== dto.requesterId && dto.requesterRole !== 'ADMIN') {
      throw new ForbiddenError('Only the author can unpublish this course');
    }
    const unpublished = await this.courses.updateStatus(dto.courseId, 'DRAFT');
    await this.knowledgeIndexer
      ?.syncCourseLifecycle({
        courseId: unpublished.id,
        visibility: 'PRIVATE_AUTHOR',
        trustTier: 'DRAFT_AI',
      })
      .catch(() => undefined);
    return unpublished;
  }
}
