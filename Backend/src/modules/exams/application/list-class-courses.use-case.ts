import { ValidationError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { assertCanUseClass } from './exam-access.js';
import { extractCourseChapterTitles } from './exam-knowledge-blueprint.service.js';

export interface ListClassCoursesDTO {
  requesterId: string;
  requesterRole: Role | null;
  classGroupId: string;
}

export interface ClassCourseOption {
  id: string;
  title: string;
  subject: string | null;
  chapters?: string[];
}

/**
 * Lists the courses the teacher may pick as AI exam sources: only courses
 * already PUBLISHED (which requires every generated section to be VALIDATED)
 * and linked to the selected class. Course bodies are never exposed here.
 */
export class ListClassCoursesUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: ListClassCoursesDTO): Promise<ClassCourseOption[]> {
    const classGroup = await this.exams.findClassGroup(dto.classGroupId);
    if (!classGroup) {
      throw new ValidationError('Unknown class', [
        { path: 'classGroupId', message: 'This class does not exist' },
      ]);
    }
    await assertCanUseClass(this.exams, dto.classGroupId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });

    const courses = await this.exams.listClassCourses(
      dto.classGroupId,
      dto.requesterId,
    );
    return courses.map((course) => {
      const chapters = extractCourseChapterTitles(course.content);
      return {
        id: course.id,
        title: course.title,
        subject: course.subject,
        ...(chapters.length > 0 ? { chapters } : {}),
      };
    });
  }
}
