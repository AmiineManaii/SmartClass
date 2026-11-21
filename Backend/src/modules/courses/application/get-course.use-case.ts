import type { Role } from '../../auth/index.js';
import type { CourseDetail } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';
import { loadReadableCourse } from './course-access.js';

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
    return loadReadableCourse(this.courses, dto, this.groups);
  }
}
