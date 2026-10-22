import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseSectionRepositoryPort } from '../../courses/domain/course-section-repository.port.js';
import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import type { ImageSearchResult, SearchPort } from '../domain/search.port.js';
import { loadOwnedCourse } from './course-access.js';

export interface SearchSectionImagesDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
  sectionKey: string;
  /** Optional teacher refinement; defaults to the section title/topics. */
  query?: string;
}

export type SearchSectionImagesResult = {
  query: string;
  images: ImageSearchResult[];
};

/**
 * Finds candidate illustrations for one section. The teacher then picks one
 * and inserts it with the apply endpoint; nothing is persisted here.
 * Search stays server-side so the image providers are not exposed and the
 * course/section ownership check is enforced (IDOR guard).
 */
export class SearchSectionImagesUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly sectionRepository: CourseSectionRepositoryPort,
    private readonly search: SearchPort,
  ) {}

  public async execute(dto: SearchSectionImagesDTO): Promise<SearchSectionImagesResult> {
    const course = await loadOwnedCourse(this.courses, dto);
    const section = await this.sectionRepository.findByKey(dto.courseId, dto.sectionKey);
    if (!section) {
      throw new NotFoundError('Course section not found');
    }

    const query =
      dto.query?.trim() ||
      [section.title, course.subject, section.keyTopics.slice(0, 3).join(' ')]
        .filter(Boolean)
        .join(' ')
        .slice(0, 200);

    const images = await this.search.searchImages(query, 5);
    return { query, images: images.slice(0, 5) };
  }
}
