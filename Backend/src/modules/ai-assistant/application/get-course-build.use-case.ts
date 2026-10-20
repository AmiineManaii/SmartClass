import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import type { CourseSectionRepositoryPort } from '../../courses/domain/course-section-repository.port.js';
import type {
  CourseSection,
  OutlineSectionInput,
} from '../../courses/domain/course-section.entity.js';
import type { CourseOutlineData } from '../../courses/domain/course.entity.js';
import { loadOwnedCourse, type CourseAccess } from './course-access.js';

export interface GetCourseBuildResult {
  course: {
    id: string;
    title: string;
    subject: string | null;
    level: string;
    difficulty: string;
    format: string;
  };
  sections: CourseSection[];
  /** True when sections were materialized from the outline by this call. */
  initializedFromOutline: boolean;
}

/**
 * Converts the persisted outline into build-ready sections. Keys are made
 * unique here because `course_sections` enforces (courseId, sectionKey).
 */
export const toOutlineInputs = (outline: CourseOutlineData): OutlineSectionInput[] => {
  const used = new Set<string>();
  return outline.sections.map((section, index) => {
    let key = section.id?.trim() || `sec-${index + 1}`;
    if (used.has(key)) key = `${key}-${index + 1}`;
    used.add(key);
    return {
      sectionKey: key,
      title: section.title.trim(),
      description: (section.description ?? '').trim(),
      keyTopics: (section.keyTopics ?? []).map((topic) => topic.trim()).filter(Boolean),
      estimatedMinutes: section.estimatedMinutes,
    };
  });
};

/**
 * Build state for the section-by-section page: the course metadata plus
 * its ordered sections. On first open, sections are materialized from the
 * teacher-validated outline (PENDING). Without an outline the list stays
 * empty and the client falls back to the monolithic generator.
 */
export class GetCourseBuildUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly sections: CourseSectionRepositoryPort,
  ) {}

  public async execute(access: CourseAccess): Promise<GetCourseBuildResult> {
    const course = await loadOwnedCourse(this.courses, access);
    let builtSections = await this.sections.listByCourse(course.id);
    let initializedFromOutline = false;

    if (builtSections.length === 0 && course.outline && course.outline.sections.length > 0) {
      builtSections = await this.sections.initFromOutline(
        course.id,
        toOutlineInputs(course.outline),
      );
      initializedFromOutline = true;
    }

    return {
      course: {
        id: course.id,
        title: course.title,
        subject: course.subject,
        level: course.level,
        difficulty: course.difficulty,
        format: course.format,
      },
      sections: builtSections,
      initializedFromOutline,
    };
  }
}
