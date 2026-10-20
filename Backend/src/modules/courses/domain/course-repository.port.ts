import type {
  CourseDetail,
  CourseDifficulty,
  CourseFormat,
  CourseLevel,
  CourseOutlineData,
  CourseStatus,
  CourseSummary,
} from './course.entity.js';

export interface SaveCourseParams {
  title: string;
  subject: string | null;
  content: string;
  level: CourseLevel;
  difficulty: CourseDifficulty;
  format: CourseFormat;
  authorId: string;
  classGroupIds?: string[];
  /** Teacher-validated plan (drives the section-by-section build). */
  outline?: CourseOutlineData | null;
}

export interface UpdateCourseParams {
  title?: string;
  subject?: string | null;
  content?: string;
  level?: CourseLevel;
  difficulty?: CourseDifficulty;
  format?: CourseFormat;
  classGroupIds?: string[];
}

export interface CourseRepositoryPort {
  /** Persists a new course (always DRAFT — validation is a separate step). */
  save(params: SaveCourseParams): Promise<CourseDetail>;
  /** Updates an existing course. */
  update(id: string, params: UpdateCourseParams): Promise<CourseDetail>;
  /** Newest-first summaries authored by one teacher. */
  listByAuthor(authorId: string): Promise<CourseSummary[]>;
  /** Newest-first summaries of validated courses (every authenticated user). */
  listPublished(): Promise<CourseSummary[]>;
  /** Full course with author display name, or null when missing. */
  findById(id: string): Promise<CourseDetail | null>;
  updateStatus(id: string, status: CourseStatus): Promise<CourseDetail>;
  remove(id: string): Promise<void>;
}
