import type { CourseSection, OutlineSectionInput, SectionStatus } from './course-section.entity.js';

export interface SaveContentParams {
  courseId: string;
  sectionKey: string;
  content: string;
  /** GENERATED when filled by the model, VALIDATED on teacher approval. */
  status?: Extract<SectionStatus, 'GENERATED' | 'VALIDATED'>;
}

export interface CourseSectionRepositoryPort {
  /**
   * (Re)creates the ordered PENDING sections of a course from the outline.
   * Existing sections are replaced so a revised outline resets the build.
   * Returns them ordered by `order`.
   */
  initFromOutline(courseId: string, sections: OutlineSectionInput[]): Promise<CourseSection[]>;
  /** Ordered sections of a course (empty array when none exist yet). */
  listByCourse(courseId: string): Promise<CourseSection[]>;
  /** Single section by composite key, or null. */
  findByKey(courseId: string, sectionKey: string): Promise<CourseSection | null>;
  /** Stores the generated Markdown body (status defaults to GENERATED). */
  saveContent(params: SaveContentParams): Promise<CourseSection>;
  /** Moves one section to a new status (teacher validation). */
  updateStatus(courseId: string, sectionKey: string, status: SectionStatus): Promise<CourseSection>;
  /** Count of sections still not VALIDATED (publish gate, RG27). */
  countNotValidated(courseId: string): Promise<number>;
}
