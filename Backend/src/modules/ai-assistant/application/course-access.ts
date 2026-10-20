import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail } from '../../courses/domain/course.entity.js';
import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';

export interface CourseAccess {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
}

/**
 * Loads a course the requester is allowed to edit.
 *
 * IDOR guard: a course that does not exist AND a course owned by someone
 * else both answer 404 — never 403 — so resource ids cannot be probed.
 * ADMIN may edit any course.
 */
export const loadOwnedCourse = async (
  courses: CourseRepositoryPort,
  access: CourseAccess,
): Promise<CourseDetail> => {
  const course = await courses.findById(access.courseId);
  if (!course) {
    throw new NotFoundError('Course not found');
  }
  if (course.authorId !== access.requesterId && access.requesterRole !== 'ADMIN') {
    throw new NotFoundError('Course not found');
  }
  return course;
};
