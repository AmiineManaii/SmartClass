/**
 * One chapter of the section-by-section build. A section is created from
 * the teacher-validated outline, filled in by the local LLM, then moved to
 * VALIDATED by the teacher (RG27: nothing reaches students before
 * validation).
 */
export type SectionStatus = 'PENDING' | 'GENERATED' | 'VALIDATED';

/** Outline entry as validated by the teacher (mirrors `course.outline`). */
export interface OutlineSectionInput {
  /** Stable key used across the build (`sec-1`, custom id, …). */
  sectionKey: string;
  title: string;
  description: string;
  keyTopics: string[];
  estimatedMinutes?: number;
}

export interface CourseSection {
  id: string;
  courseId: string;
  sectionKey: string;
  title: string;
  description: string;
  keyTopics: string[];
  /** Markdown body of the section (null until generated). */
  content: string | null;
  order: number;
  estimatedMinutes: number;
  status: SectionStatus;
}
