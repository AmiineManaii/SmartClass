import { ForbiddenError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseDetail, CourseDifficulty, CourseFormat, CourseLevel } from '../domain/course.entity.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';
import type { KnowledgeIndexerPort } from '../../knowledge/domain/knowledge-indexer.port.js';

export interface UpdateCourseDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
  title?: string;
  subject?: string | null;
  content?: string;
  level?: CourseLevel;
  difficulty?: CourseDifficulty;
  format?: CourseFormat;
  classGroupIds?: string[];
}

/** Updates an existing course (author or admin). */
export class UpdateCourseUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly groups?: GroupRepositoryPort,
    private readonly knowledgeIndexer?: KnowledgeIndexerPort,
  ) {}

  public async execute(dto: UpdateCourseDTO): Promise<CourseDetail> {
    const course = await this.courses.findById(dto.courseId);
    if (!course) {
      throw new NotFoundError('Course not found');
    }
    if (course.authorId !== dto.requesterId && dto.requesterRole !== 'ADMIN') {
      throw new ForbiddenError('Only the author or an administrator can update this course');
    }

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

    const updated = await this.courses.update(dto.courseId, {
      title: dto.title,
      subject: dto.subject,
      content: dto.content,
      level: dto.level,
      difficulty: dto.difficulty,
      format: dto.format,
      classGroupIds: dto.classGroupIds,
    });

    const isPublished = updated.status === 'PUBLISHED';
    this.knowledgeIndexer?.enqueueIndex({
      sourceType: 'COURSE',
      sourceId: updated.id,
      authorId: updated.authorId,
      title: updated.title,
      subject: updated.subject,
      visibility: isPublished ? 'CLASS_PUBLISHED' : 'PRIVATE_AUTHOR',
      trustTier: isPublished ? 'VERIFIED' : 'DRAFT_AI',
      classGroupIds: updated.classGroupIds,
      content: updated.content,
      metadata: {
        courseId: updated.id,
        level: updated.level,
        difficulty: updated.difficulty,
        format: updated.format,
      },
    });

    return updated;
  }
}

