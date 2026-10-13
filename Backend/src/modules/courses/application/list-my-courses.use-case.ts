import type { CourseSummary } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';

/** Teacher's own courses (drafts + published, newest first). */
export class ListMyCoursesUseCase {
  constructor(private readonly courses: CourseRepositoryPort) {}

  public async execute(authorId: string): Promise<CourseSummary[]> {
    return this.courses.listByAuthor(authorId);
  }
}
