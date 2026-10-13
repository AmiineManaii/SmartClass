import type {
  CourseDetail,
  CourseDifficulty,
  CourseFormat,
  CourseLevel,
} from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';

export interface SaveCourseDTO {
  requesterId: string;
  title: string;
  subject?: string | null;
  content: string;
  level: CourseLevel;
  difficulty?: CourseDifficulty;
  format?: CourseFormat;
}

/** Saves a generated course as DRAFT (not visible to students yet). */
export class SaveCourseUseCase {
  constructor(private readonly courses: CourseRepositoryPort) {}

  public async execute(dto: SaveCourseDTO): Promise<CourseDetail> {
    return this.courses.save({
      title: dto.title.trim(),
      subject: dto.subject?.trim() ? dto.subject.trim() : null,
      content: dto.content,
      level: dto.level,
      difficulty: dto.difficulty ?? 'moyen',
      format: dto.format ?? 'resume',
      authorId: dto.requesterId,
    });
  }
}
