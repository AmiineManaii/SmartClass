import type { Role } from '../../auth/index.js';
import type { CourseSummary } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';

/**
 * Validated courses (newest first). Unrestricted courses are visible to all;
 * class-scoped courses are only visible to members of those classes (or admins).
 */
export class ListPublishedCoursesUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly groups?: GroupRepositoryPort,
  ) {}

  public async execute(
    requesterId?: string,
    requesterRole?: Role | null,
  ): Promise<CourseSummary[]> {
    const published = await this.courses.listPublished();
    if (!requesterId || requesterRole === 'ADMIN' || !this.groups) {
      return published;
    }

    const myGroups = await this.groups.listMyGroups(requesterId);
    const myGroupIds = new Set(myGroups.map((g) => g.id));

    return published.filter((course) => {
      if (course.authorId === requesterId) return true;
      const classGroupIds = course.classGroupIds ?? [];
      if (classGroupIds.length === 0) return true;
      return classGroupIds.some((id) => myGroupIds.has(id));
    });
  }
}

