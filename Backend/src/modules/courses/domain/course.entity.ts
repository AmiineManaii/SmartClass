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
  createdAt: Date;
  updatedAt: Date;
}

/** Full course with the Markdown body (detail view / reader). */
export interface CourseDetail extends CourseSummary {
  content: string;
}
