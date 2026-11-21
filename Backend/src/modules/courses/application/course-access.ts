import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';

export interface CourseAccessRequest {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
}

/**
 * Loads a course the requester is allowed to READ.
 *
 * Published courses are visible to authenticated users enrolled in (or
 * teaching) at least one linked class group, or to everyone when the course
 * is not restricted. Drafts answer 404 to anyone but the author and admins
 * (IDOR: no existence oracle).
 */
export const loadReadableCourse = async (
  courses: CourseRepositoryPort,
  access: CourseAccessRequest,
  groups?: GroupRepositoryPort,
): Promise<CourseDetail> => {
  const course = await courses.findById(access.courseId);
  if (!course) {
    throw new NotFoundError('Course not found');
  }
  if (course.authorId === access.requesterId || access.requesterRole === 'ADMIN') {
    return course;
  }
  if (course.status !== 'PUBLISHED') {
    throw new NotFoundError('Course not found');
  }

  if (groups && course.classGroupIds && course.classGroupIds.length > 0) {
    const myGroups = await groups.listMyGroups(access.requesterId);
    const myGroupIds = new Set(myGroups.map((group) => group.id));
    const hasAccess = course.classGroupIds.some((id) => myGroupIds.has(id));
    if (!hasAccess) {
      throw new NotFoundError('Course not found');
    }
  }

  return course;
};
