import { Prisma } from '@prisma/client';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type {
  CourseStudyArtifact,
  CourseStudyArtifactKind,
  CourseStudyLanguage,
  CourseTutorCitation,
  CourseTutorConversation,
  CourseTutorMessage,
} from '../domain/course-study.entity.js';
import type {
  AppendCourseTutorMessageParams,
  CourseStudyRepositoryPort,
  CreateCourseStudyArtifactParams,
  CreateCourseTutorConversationParams,
} from '../domain/course-study-repository.port.js';

interface RawArtifactRow {
  id: string;
  courseId: string;
  userId: string;
  kind: string;
  title: string;
  language: string;
  config: unknown;
  content: unknown;
  modelUsed: string | null;
  createdAt: Date;
  updatedAt: Date;
}

interface RawMessageRow {
  id: string;
  conversationId: string;
  role: string;
  content: string;
  citations: unknown;
  inScope: boolean;
  modelUsed: string | null;
  createdAt: Date;
}

interface RawConversationRow {
  id: string;
  courseId: string;
  userId: string;
  title: string;
  createdAt: Date;
  updatedAt: Date;
  messages?: RawMessageRow[];
}

const asRecord = (value: unknown): Record<string, unknown> =>
  value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};

const toCitations = (value: unknown): CourseTutorCitation[] => {
  if (!Array.isArray(value)) return [];
  return value
    .filter((entry): entry is Record<string, unknown> => Boolean(entry) && typeof entry === 'object')
    .map((entry) => ({
      passageId: typeof entry.passageId === 'string' ? entry.passageId : '',
      sectionTitle: typeof entry.sectionTitle === 'string' ? entry.sectionTitle : '',
      excerpt: typeof entry.excerpt === 'string' ? entry.excerpt : '',
      score: typeof entry.score === 'number' ? entry.score : 0,
    }));
};

const toArtifact = (row: RawArtifactRow): CourseStudyArtifact => ({
  id: row.id,
  courseId: row.courseId,
  userId: row.userId,
  kind: row.kind as CourseStudyArtifactKind,
  title: row.title,
  language: row.language as CourseStudyLanguage,
  config: asRecord(row.config),
  content: asRecord(row.content),
  modelUsed: row.modelUsed,
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
});

const toMessage = (row: RawMessageRow): CourseTutorMessage => ({
  id: row.id,
  conversationId: row.conversationId,
  role: row.role === 'assistant' ? 'assistant' : 'user',
  content: row.content,
  citations: toCitations(row.citations),
  inScope: row.inScope,
  modelUsed: row.modelUsed,
  createdAt: row.createdAt,
});

const toConversation = (row: RawConversationRow): CourseTutorConversation => ({
  id: row.id,
  courseId: row.courseId,
  userId: row.userId,
  title: row.title,
  messages: (row.messages ?? []).map(toMessage),
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
});

/** Prisma adapter for `course_study_artifacts` and course tutor threads. */
export class PrismaCourseStudyRepositoryAdapter
  implements CourseStudyRepositoryPort
{
  private get prisma() {
    return getPrismaClient();
  }

  public async listArtifacts(
    courseId: string,
    userId: string,
  ): Promise<CourseStudyArtifact[]> {
    const rows = (await this.prisma.courseStudyArtifact.findMany({
      where: { courseId, userId },
      orderBy: { createdAt: 'desc' },
    })) as unknown as RawArtifactRow[];
    return rows.map(toArtifact);
  }

  public async createArtifact(
    params: CreateCourseStudyArtifactParams,
  ): Promise<CourseStudyArtifact> {
    const row = (await this.prisma.courseStudyArtifact.create({
      data: {
        courseId: params.courseId,
        userId: params.userId,
        kind: params.kind,
        title: params.title,
        language: params.language,
        config: params.config as unknown as Prisma.InputJsonValue,
        content: params.content as unknown as Prisma.InputJsonValue,
        modelUsed: params.modelUsed,
      },
    })) as unknown as RawArtifactRow;
    return toArtifact(row);
  }

  public async deleteArtifact(artifactId: string, userId: string): Promise<boolean> {
    const result = await this.prisma.courseStudyArtifact.deleteMany({
      where: { id: artifactId, userId },
    });
    return result.count > 0;
  }

  public async listConversations(
    courseId: string,
    userId: string,
  ): Promise<CourseTutorConversation[]> {
    const rows = (await this.prisma.courseTutorConversation.findMany({
      where: { courseId, userId },
      orderBy: { updatedAt: 'desc' },
      take: 20,
      include: { messages: { orderBy: { createdAt: 'asc' }, take: 100 } },
    })) as unknown as RawConversationRow[];
    return rows.map(toConversation);
  }

  public async findConversation(
    conversationId: string,
    userId: string,
  ): Promise<CourseTutorConversation | null> {
    const row = (await this.prisma.courseTutorConversation.findFirst({
      where: { id: conversationId, userId },
      include: { messages: { orderBy: { createdAt: 'asc' }, take: 100 } },
    })) as unknown as RawConversationRow | null;
    return row ? toConversation(row) : null;
  }

  public async createConversation(
    params: CreateCourseTutorConversationParams,
  ): Promise<CourseTutorConversation> {
    const row = (await this.prisma.courseTutorConversation.create({
      data: {
        courseId: params.courseId,
        userId: params.userId,
        title: params.title,
      },
      include: { messages: true },
    })) as unknown as RawConversationRow;
    return toConversation(row);
  }

  public async appendMessage(
    params: AppendCourseTutorMessageParams,
  ): Promise<CourseTutorMessage> {
    const row = (await this.prisma.courseTutorMessage.create({
      data: {
        conversationId: params.conversationId,
        role: params.role,
        content: params.content,
        citations: (params.citations ?? []) as unknown as Prisma.InputJsonValue,
        inScope: params.inScope ?? true,
        modelUsed: params.modelUsed ?? null,
      },
    })) as unknown as RawMessageRow;
    await this.prisma.courseTutorConversation.update({
      where: { id: params.conversationId },
      data: { updatedAt: new Date() },
    });
    return toMessage(row);
  }
}
