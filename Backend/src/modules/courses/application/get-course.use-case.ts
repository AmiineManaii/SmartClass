import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';

export interface GetCourseDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
}

/**
 * Reads one course. Published courses are visible to authenticated users
 * who are either unrestricted (classGroupIds empty), or enrolled in/assigned
 * to at least one of the linked class groups.
 * Drafts only visible to author or admin.
 */
export class GetCourseUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly groups?: GroupRepositoryPort,
  ) {}

  public async execute(dto: GetCourseDTO): Promise<CourseDetail> {
    const course = await this.courses.findById(dto.courseId);
    if (!course) {
      throw new NotFoundError('Course not found');
    }
    if (course.authorId === dto.requesterId || dto.requesterRole === 'ADMIN') {
      return course;
    }
    if (course.status !== 'PUBLISHED') {
      throw new NotFoundError('Course not found');
    }

    if (this.groups && course.classGroupIds && course.classGroupIds.length > 0) {
      const myGroups = await this.groups.listMyGroups(dto.requesterId);
      const myGroupIds = new Set(myGroups.map((g) => g.id));
      const hasAccess = course.classGroupIds.some((id) => myGroupIds.has(id));
      if (!hasAccess) {
        throw new NotFoundError('Course not found');
      }
    }

    return course;
  }
}

