import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { KnowledgeIndexerPort } from '../../knowledge/domain/knowledge-indexer.port.js';

export interface DeleteCourseDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
}

/** Deletes a course (author or admin). */
export class DeleteCourseUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly knowledgeIndexer?: KnowledgeIndexerPort,
  ) {}

  public async execute(dto: DeleteCourseDTO): Promise<{ id: string; deleted: boolean }> {
    const course = await this.courses.findById(dto.courseId);
    if (!course) {
      throw new NotFoundError('Course not found');
    }
    if (course.authorId !== dto.requesterId && dto.requesterRole !== 'ADMIN') {
      throw new ForbiddenError('Only the author can delete this course');
    }
    await this.courses.remove(dto.courseId);
    await this.knowledgeIndexer?.removeByCourseId(dto.courseId).catch(() => undefined);
    return { id: dto.courseId, deleted: true };
  }
}
