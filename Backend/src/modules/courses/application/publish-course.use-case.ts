import {
  ForbiddenError,
  NotFoundError,
  SectionsNotValidatedError,
} from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { CourseSectionRepositoryPort } from '../domain/course-section-repository.port.js';

export interface PublishCourseDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
}

/**
 * Validates a draft (author or admin): it becomes readable by all users.
 *
 * Section builds add an extra gate (RG27): if the course has sections,
 * every one of them must be VALIDATED by the teacher first — otherwise
 * the publication is refused with 409 SECTIONS_NOT_VALIDATED. Courses
 * generated as a single document (no sections) publish as before.
 */
export class PublishCourseUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly sections?: CourseSectionRepositoryPort,
  ) {}

  public async execute(dto: PublishCourseDTO): Promise<CourseDetail> {
    const course = await this.courses.findById(dto.courseId);
    if (!course) {
      throw new NotFoundError('Course not found');
    }
    if (course.authorId !== dto.requesterId && dto.requesterRole !== 'ADMIN') {
      throw new ForbiddenError('Only the author can validate this course');
    }

    if (this.sections) {
      const remaining = await this.sections.countNotValidated(dto.courseId);
      if (remaining > 0) {
        throw new SectionsNotValidatedError(
          remaining === 1
            ? 'All sections must be validated before publishing (1 section left)'
            : `All sections must be validated before publishing (${remaining} sections left)`,
          [{ path: 'sections', message: `${remaining} section(s) not validated` }],
        );
      }
    }

    return this.courses.updateStatus(dto.courseId, 'PUBLISHED');
  }
}
