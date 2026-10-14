import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type {
  CourseDetail,
  CourseDifficulty,
  CourseFormat,
  CourseLevel,
  CourseStatus,
  CourseSummary,
} from '../domain/course.entity.js';
import type {
  CourseRepositoryPort,
  SaveCourseParams,
  UpdateCourseParams,
} from '../domain/course-repository.port.js';

interface RawCourseRow {
  id: string;
  title: string;
  subject: string | null;
  content: string;
  level: string;
  difficulty: string;
  format: string;
  status: string;
  authorId: string;
  createdAt: Date;
  updatedAt: Date;
  author: { firstName: string; lastName: string };
}

const authorName = (row: RawCourseRow): string =>
  `${row.author.firstName} ${row.author.lastName}`.trim();

export class PrismaCourseRepositoryAdapter implements CourseRepositoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  private toSummary(row: RawCourseRow): CourseSummary {
    return {
      id: row.id,
      title: row.title,
      subject: row.subject,
      level: row.level as CourseLevel,
      difficulty: row.difficulty as CourseDifficulty,
      format: row.format as CourseFormat,
      status: row.status as CourseStatus,
      authorId: row.authorId,
      authorName: authorName(row),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    };
  }

  private toDetail(row: RawCourseRow): CourseDetail {
    return { ...this.toSummary(row), content: row.content };
  }

  private get withAuthor() {
    return { author: { select: { firstName: true, lastName: true } } } as const;
  }

  public async save(params: SaveCourseParams): Promise<CourseDetail> {
    const row = (await this.prisma.course.create({
      data: {
        title: params.title,
        subject: params.subject,
        content: params.content,
        level: params.level,
        difficulty: params.difficulty,
        format: params.format,
        status: 'DRAFT',
        authorId: params.authorId,
      },
      include: this.withAuthor,
    })) as unknown as RawCourseRow;
    return this.toDetail(row);
  }

  public async update(id: string, params: UpdateCourseParams): Promise<CourseDetail> {
    const row = (await this.prisma.course.update({
      where: { id },
      data: {
        ...(params.title !== undefined ? { title: params.title } : {}),
        ...(params.subject !== undefined ? { subject: params.subject } : {}),
        ...(params.content !== undefined ? { content: params.content } : {}),
        ...(params.level !== undefined ? { level: params.level } : {}),
        ...(params.difficulty !== undefined ? { difficulty: params.difficulty } : {}),
        ...(params.format !== undefined ? { format: params.format } : {}),
      },
      include: this.withAuthor,
    })) as unknown as RawCourseRow;
    return this.toDetail(row);
  }

  public async listByAuthor(authorId: string): Promise<CourseSummary[]> {
    const rows = (await this.prisma.course.findMany({
      where: { authorId },
      orderBy: { createdAt: 'desc' },
      include: this.withAuthor,
    })) as unknown as RawCourseRow[];
    return rows.map((row) => this.toSummary(row));
  }

  public async listPublished(): Promise<CourseSummary[]> {
    const rows = (await this.prisma.course.findMany({
      where: { status: 'PUBLISHED' },
      orderBy: { createdAt: 'desc' },
      include: this.withAuthor,
    })) as unknown as RawCourseRow[];
    return rows.map((row) => this.toSummary(row));
  }

  public async findById(id: string): Promise<CourseDetail | null> {
    const row = (await this.prisma.course.findUnique({
      where: { id },
      include: this.withAuthor,
    })) as unknown as RawCourseRow | null;
    return row ? this.toDetail(row) : null;
  }

  public async updateStatus(id: string, status: CourseStatus): Promise<CourseDetail> {
    const row = (await this.prisma.course.update({
      where: { id },
      data: { status },
      include: this.withAuthor,
    })) as unknown as RawCourseRow;
    return this.toDetail(row);
  }

  public async remove(id: string): Promise<void> {
    await this.prisma.course.delete({ where: { id } });
  }
}
