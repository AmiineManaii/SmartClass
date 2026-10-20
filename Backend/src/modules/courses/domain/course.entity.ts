/** Course content status: DRAFT (author + admins only) or PUBLISHED (all users). */
export type CourseStatus = 'DRAFT' | 'PUBLISHED';

export type CourseLevel = 'concis' | 'equilibre' | 'detaille';

export type CourseDifficulty = 'facile' | 'moyen' | 'difficile';

export type CourseFormat = 'resume' | 'flashcards' | 'carte-mentale';

/** Lightweight course row for listings (no Markdown body). */
export interface CourseSummary {
  id: string;
  title: string;
  subject: string | null;
  level: CourseLevel;
  difficulty: CourseDifficulty;
  format: CourseFormat;
  status: CourseStatus;
  authorId: string;
  authorName: string;
  classGroupIds?: string[];
  createdAt: Date;
  updatedAt: Date;
}

/** Full course with the Markdown body (detail view / reader). */
export interface CourseDetail extends CourseSummary {
  content: string;
  /** Teacher-validated outline (plan) persisted for the section build. */
  outline: CourseOutlineData | null;
}

/** One entry of the persisted, teacher-validated outline. */
export type CourseOutlineSectionData = {
  /** Stable key used as `course_sections.section_key` (`sec-1`, …). */
  id?: string;
  title: string;
  description?: string;
  keyTopics?: string[];
  estimatedMinutes?: number;
};

export type CourseOutlineData = {
  title: string;
  targetAudience?: string;
  prerequisites?: string[];
  description?: string;
  sections: CourseOutlineSectionData[];
};
