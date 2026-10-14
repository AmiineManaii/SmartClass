import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail, CourseDifficulty, CourseFormat, CourseLevel } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';

export interface UpdateCourseDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
  title?: string;
  subject?: string | null;
  content?: string;
  level?: CourseLevel;
  difficulty?: CourseDifficulty;
  format?: CourseFormat;
}

/** Updates an existing course (author or admin). */
export class UpdateCourseUseCase {
  constructor(private readonly courses: CourseRepositoryPort) {}

  public async execute(dto: UpdateCourseDTO): Promise<CourseDetail> {
    const course = await this.courses.findById(dto.courseId);
    if (!course) {
      throw new NotFoundError('Course not found');
    }
    if (course.authorId !== dto.requesterId && dto.requesterRole !== 'ADMIN') {
      throw new ForbiddenError('Only the author or an administrator can update this course');
    }

    return this.courses.update(dto.courseId, {
      title: dto.title,
      subject: dto.subject,
      content: dto.content,
      level: dto.level,
      difficulty: dto.difficulty,
      format: dto.format,
    });
  }
}
