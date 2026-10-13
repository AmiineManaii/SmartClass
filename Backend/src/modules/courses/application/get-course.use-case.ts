import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';

export interface GetCourseDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
}

/**
 * Reads one course. Published courses are visible to every authenticated
 * user; drafts only to their author (or an admin). Unknown or forbidden
 * drafts surface as 404 so draft existence never leaks.
 */
export class GetCourseUseCase {
  constructor(private readonly courses: CourseRepositoryPort) {}

  public async execute(dto: GetCourseDTO): Promise<CourseDetail> {
    const course = await this.courses.findById(dto.courseId);
    if (!course) {
      throw new NotFoundError('Course not found');
    }
    if (course.status === 'PUBLISHED') return course;
    if (course.authorId === dto.requesterId || dto.requesterRole === 'ADMIN') {
      return course;
    }
    throw new NotFoundError('Course not found');
  }
}
