import { ConflictError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseSectionRepositoryPort } from '../../courses/domain/course-section-repository.port.js';
import type { CourseSection } from '../../courses/domain/course-section.entity.js';
import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import { loadOwnedCourse } from './course-access.js';
import type { SectionMemoryService } from './section-memory.service.js';

export interface ValidateSectionDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
  sectionKey: string;
}

export interface ValidateSectionResult {
  section: CourseSection;
  /** Reassembled course Markdown (all sections that have content). */
  courseContent: string;
  /** Sections still awaiting validation (0 → the course may be published). */
  remainingToValidate: number;
}

/**
 * Assembles the draft course body from its sections: the reader (and the
 * published course) always sees one coherent document, while validation
 * stays a per-section gate (RG27/RG4).
 */
export const assembleCourseContent = (
  title: string,
  sections: CourseSection[],
): string => {
  const parts = [`# ${title}`];
  for (const section of sections) {
    const body = section.content?.trim();
    if (body) parts.push(body);
  }
  return parts.join('\n\n');
};

/**
 * Teacher approves one generated section: it becomes VALIDATED, its
 * content is remembered in the author's vector memory (so later edits of
 * other courses recall it), and the draft course body is reassembled.
 */
export class ValidateSectionUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly sectionRepository: CourseSectionRepositoryPort,
    private readonly memory: SectionMemoryService,
  ) {}

  public async execute(dto: ValidateSectionDTO): Promise<ValidateSectionResult> {
    const course = await loadOwnedCourse(this.courses, dto);
    const section = await this.sectionRepository.findByKey(dto.courseId, dto.sectionKey);
    if (!section) {
      throw new NotFoundError('Course section not found');
    }
    if (!section.content || section.content.trim().length === 0) {
      throw new ConflictError('This section has no generated content to validate yet');
    }

    const updated = await this.sectionRepository.updateStatus(
      dto.courseId,
      dto.sectionKey,
      'VALIDATED',
    );

    await this.memory.remember({
      authorId: course.authorId,
      courseId: course.id,
      sectionId: section.id,
      subject: course.subject,
      title: section.title,
      content: section.content,
    });

    const sections = await this.sectionRepository.listByCourse(dto.courseId);
    const courseContent = assembleCourseContent(course.title, sections);
    await this.courses.update(dto.courseId, { content: courseContent });

    return {
      section: updated,
      courseContent,
      remainingToValidate: sections.filter((item) => item.status !== 'VALIDATED').length,
    };
  }
}
