import { ForbiddenError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type {
  CourseDetail,
  CourseDifficulty,
  CourseFormat,
  CourseLevel,
} from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';

export interface SaveCourseDTO {
  requesterId: string;
  requesterRole?: Role | null;
  title: string;
  subject?: string | null;
  content: string;
  level: CourseLevel;
  difficulty?: CourseDifficulty;
  format?: CourseFormat;
  classGroupIds?: string[];
}

/** Saves a generated course as DRAFT (not visible to students yet). */
export class SaveCourseUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly groups?: GroupRepositoryPort,
  ) {}

  public async execute(dto: SaveCourseDTO): Promise<CourseDetail> {
    if (
      this.groups &&
      dto.classGroupIds &&
      dto.classGroupIds.length > 0 &&
      dto.requesterRole !== 'ADMIN'
    ) {
      for (const groupId of dto.classGroupIds) {
        const authorized = await this.groups.isTeacherAuthorizedForGroup(
          groupId,
          dto.requesterId,
        );
        if (!authorized) {
          throw new ForbiddenError(
            `You are not authorized to assign courses to class group ${groupId}`,
          );
        }
      }
    }

    return this.courses.save({
      title: dto.title.trim(),
      subject: dto.subject?.trim() ? dto.subject.trim() : null,
      content: dto.content,
      level: dto.level,
      difficulty: dto.difficulty ?? 'moyen',
      format: dto.format ?? 'resume',
      authorId: dto.requesterId,
      classGroupIds: dto.classGroupIds,
    });
  }
}

