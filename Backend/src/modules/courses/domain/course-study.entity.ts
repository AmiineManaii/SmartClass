/**
 * Student study material generated from one published course.
 *
 * RG4: the teacher validates the course content first; RG6/RG7: the AI
 * artifacts and the tutor conversation stay private to the student.
 */
export type CourseStudyArtifactKind = 'SUMMARY' | 'FLASHCARDS';

export type CourseSummaryMode =
  | 'short'
  | 'medium'
  | 'detailed'
  | 'exam'
  | 'eli15'
  | 'bullet_points';

export type CourseStudyLanguage = 'fr' | 'en' | 'auto';

/** One chapter of the course, used as the citation unit. */
export interface CoursePassage {
  /** Stable index inside the course (`p-1`, `p-2`, …). */
  id: string;
  /** Markdown heading path, e.g. `Chapitre 2 — Les boucles`. */
  title: string;
  /** Heading level that opened the passage (1 = `#`, 2 = `##`, …). */
  level: number;
  content: string;
}

export interface CourseSummarySectionExcerpt {
  title: string;
  excerpt: string;
}

export interface CourseSummaryContent {
  mode: CourseSummaryMode;
  markdown: string;
  keyTakeaways: string[];
  sections: CourseSummarySectionExcerpt[];
}

export interface CourseFlashcard {
  id: string;
  front: string;
  back: string;
  sectionTitle: string | null;
}

export interface CourseFlashcardsContent {
  focus: string;
  cards: CourseFlashcard[];
}

export interface CourseStudyArtifact {
  id: string;
  courseId: string;
  userId: string;
  kind: CourseStudyArtifactKind;
  title: string;
  language: CourseStudyLanguage;
  config: Record<string, unknown>;
  content: CourseSummaryContent | CourseFlashcardsContent | Record<string, unknown>;
  modelUsed: string | null;
  createdAt: Date;
  updatedAt: Date;
}

/** Source excerpt backing one tutor answer (never invented). */
export interface CourseTutorCitation {
  /** `p-1`, `p-2`… — the passage the excerpt comes from. */
  passageId: string;
  sectionTitle: string;
  excerpt: string;
  score: number;
}

export interface CourseTutorMessage {
  id: string;
  conversationId: string;
  role: 'user' | 'assistant';
  content: string;
  citations: CourseTutorCitation[];
  /** False when the question was outside the course (deterministic refusal). */
  inScope: boolean;
  modelUsed: string | null;
  createdAt: Date;
}

export interface CourseTutorConversation {
  id: string;
  courseId: string;
  userId: string;
  title: string;
  messages: CourseTutorMessage[];
  createdAt: Date;
  updatedAt: Date;
}
