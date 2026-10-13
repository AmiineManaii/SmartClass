import type { CourseSummary } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';

/** Validated courses (newest first) — readable by every authenticated user. */
export class ListPublishedCoursesUseCase {
  constructor(private readonly courses: CourseRepositoryPort) {}

  public async execute(): Promise<CourseSummary[]> {
    return this.courses.listPublished();
  }
}
