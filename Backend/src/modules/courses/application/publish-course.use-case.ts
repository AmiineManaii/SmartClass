import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';

export interface PublishCourseDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
}

/** Validates a draft (author or admin): it becomes readable by all users. */
export class PublishCourseUseCase {
  constructor(private readonly courses: CourseRepositoryPort) {}

  public async execute(dto: PublishCourseDTO): Promise<CourseDetail> {
    const course = await this.courses.findById(dto.courseId);
    if (!course) {
      throw new NotFoundError('Course not found');
    }
    if (course.authorId !== dto.requesterId && dto.requesterRole !== 'ADMIN') {
      throw new ForbiddenError('Only the author can validate this course');
    }
    return this.courses.updateStatus(dto.courseId, 'PUBLISHED');
  }
}
