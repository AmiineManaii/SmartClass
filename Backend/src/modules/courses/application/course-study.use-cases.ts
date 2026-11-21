import type { Role } from '../../auth/index.js';
import type {
  CourseStudyArtifact,
  CourseTutorConversation,
} from '../domain/course-study.entity.js';
import type { CourseStudyRepositoryPort } from '../domain/course-study-repository.port.js';
import type { CourseRepositoryPort } from '../domain/course-repository.port.js';
import type { GroupRepositoryPort } from '../../groups/domain/group-repository.port.js';
import { splitCoursePassages } from '../domain/course-grounding.js';
import { loadReadableCourse } from './course-access.js';

export interface CourseStudyWorkspace {
  courseId: string;
  courseTitle: string;
  /** Chapters available as flashcard/summary focus. */
  chapters: Array<{ id: string; title: string }>;
  artifacts: CourseStudyArtifact[];
  conversations: CourseTutorConversation[];
}

/** Everything the student study screen needs, in one round-trip. */
export class GetCourseStudyWorkspaceUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly groups: GroupRepositoryPort | undefined,
    private readonly study: CourseStudyRepositoryPort,
  ) {}

  public async execute(input: {
    requesterId: string;
    requesterRole: Role | null;
    courseId: string;
  }): Promise<CourseStudyWorkspace> {
    const course = await loadReadableCourse(
      this.courses,
      {
        requesterId: input.requesterId,
        requesterRole: input.requesterRole,
        courseId: input.courseId,
      },
      this.groups,
    );

    const [artifacts, conversations] = await Promise.all([
      this.study.listArtifacts(course.id, input.requesterId),
      this.study.listConversations(course.id, input.requesterId),
    ]);

    return {
      courseId: course.id,
      courseTitle: course.title,
      chapters: splitCoursePassages(course.content, course.title).map((passage) => ({
        id: passage.id,
        title: passage.title,
      })),
      artifacts,
      conversations,
    };
  }
}

/** Deletes one artifact of the caller (never another student's). */
export class DeleteCourseStudyArtifactUseCase {
  constructor(
    private readonly courses: CourseRepositoryPort,
    private readonly groups: GroupRepositoryPort | undefined,
    private readonly study: CourseStudyRepositoryPort,
  ) {}

  public async execute(input: {
    requesterId: string;
    requesterRole: Role | null;
    courseId: string;
    artifactId: string;
  }): Promise<{ deleted: boolean }> {
    await loadReadableCourse(
      this.courses,
      {
        requesterId: input.requesterId,
        requesterRole: input.requesterRole,
        courseId: input.courseId,
      },
      this.groups,
    );
    const deleted = await this.study.deleteArtifact(input.artifactId, input.requesterId);
    return { deleted };
  }
}
