import { BadRequestError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseSection } from '../../courses/domain/course-section.entity.js';
import type { CourseSectionRepositoryPort } from '../../courses/domain/course-section-repository.port.js';
import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import { loadOwnedCourse } from './course-access.js';

export interface ApplySectionImageDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
  sectionKey: string;
  imageUrl: string;
  caption?: string;
}

const httpUrl = (raw: string): string => {
  let parsed: URL;
  try {
    parsed = new URL(raw);
  } catch {
    throw new BadRequestError('imageUrl must be a valid URL');
  }
  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') {
    throw new BadRequestError('imageUrl must use http or https');
  }
  // Markdown link destinations cannot contain raw parentheses.
  return parsed.toString().replace(/\(/g, '%28').replace(/\)/g, '%29');
};

const altText = (caption: string | undefined, fallback: string): string => {
  const clean = (caption ?? '').replace(/[[\]\r\n]/g, ' ').replace(/\s+/g, ' ').trim();
  return (clean || fallback).slice(0, 180);
};

/**
 * Inserts the illustration image directly under the section title & introductory paragraph/definition.
 */
const insertAfterIntro = (body: string, markdown: string): string => {
  const lines = body.split('\n');
  let firstHeadingIdx = -1;
  let introEndIdx = -1;

  for (let i = 0; i < lines.length; i++) {
    const trimmed = lines[i].trim();
    if (firstHeadingIdx === -1) {
      if (trimmed.startsWith('#')) {
        firstHeadingIdx = i;
      }
    } else {
      // Find the first paragraph (definition/intro) following the heading
      if (trimmed && !trimmed.startsWith('#') && !trimmed.startsWith('![')) {
        let end = i;
        while (end + 1 < lines.length && lines[end + 1].trim() && !lines[end + 1].trim().startsWith('#')) {
          end++;
        }
        introEndIdx = end;
        break;
      }
    }
  }

  if (introEndIdx !== -1) {
    const before = lines.slice(0, introEndIdx + 1).join('\n');
    const after = lines.slice(introEndIdx + 1).join('\n');
    if (after.trim().length > 0) {
      return `${before}\n\n${markdown.trim()}\n\n${after.trimStart()}\n`;
    }
    return `${before}\n\n${markdown.trim()}\n`;
  }

  // If there is only a title and no paragraph yet, insert right after the title
  if (firstHeadingIdx !== -1) {
    const before = lines.slice(0, firstHeadingIdx + 1).join('\n');
    const after = lines.slice(firstHeadingIdx + 1).join('\n');
    if (after.trim().length > 0) {
      return `${before}\n\n${markdown.trim()}\n\n${after.trimStart()}\n`;
    }
    return `${before}\n\n${markdown.trim()}\n`;
  }

  // Fallback: prepend at the top
  return `${markdown.trim()}\n\n${body}`;
};

/**
 * Inserts a teacher-chosen web image near the top (after title and intro/definition)
 * and demotes a validated section back to GENERATED (it must be re-approved).
 */
export class ApplySectionImageUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly sectionRepository: CourseSectionRepositoryPort,
  ) {}

  public async execute(dto: ApplySectionImageDTO): Promise<{ section: CourseSection }> {
    await loadOwnedCourse(this.courses, dto);
    const section = await this.sectionRepository.findByKey(dto.courseId, dto.sectionKey);
    if (!section) {
      throw new NotFoundError('Course section not found');
    }
    const body = section.content?.trim();
    if (!body) {
      throw new BadRequestError('Generate the section before adding an illustration');
    }

    const imageUrl = httpUrl(dto.imageUrl);
    if (body.includes(`](${imageUrl})`) || body.includes(`](${dto.imageUrl.trim()})`)) {
      return { section };
    }

    const markdown = `![${altText(dto.caption, section.title)}](${imageUrl})`;
    const updatedContent = insertAfterIntro(body, markdown);

    const saved = await this.sectionRepository.saveContent({
      courseId: dto.courseId,
      sectionKey: dto.sectionKey,
      content: updatedContent,
      status: 'GENERATED',
    });
    return { section: saved };
  }
}
