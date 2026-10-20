import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type {
  CourseSection,
  OutlineSectionInput,
  SectionStatus,
} from '../domain/course-section.entity.js';
import type {
  CourseSectionRepositoryPort,
  SaveContentParams,
} from '../domain/course-section-repository.port.js';

interface RawSectionRow {
  id: string;
  courseId: string;
  sectionKey: string;
  title: string;
  description: string;
  keyTopics: string[];
  content: string | null;
  order: number;
  estimatedMinutes: number | null;
  status: string;
}

const DEFAULT_MINUTES = 15;

export class PrismaCourseSectionRepositoryAdapter implements CourseSectionRepositoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  private toSection(row: RawSectionRow): CourseSection {
    return {
      id: row.id,
      courseId: row.courseId,
      sectionKey: row.sectionKey,
      title: row.title,
      description: row.description ?? '',
      keyTopics: row.keyTopics ?? [],
      content: row.content,
      order: row.order,
      estimatedMinutes: row.estimatedMinutes ?? DEFAULT_MINUTES,
      status: row.status as SectionStatus,
    };
  }

  public async initFromOutline(
    courseId: string,
    sections: OutlineSectionInput[],
  ): Promise<CourseSection[]> {
    // Reset on re-init: a revised outline replaces the whole build.
    await this.prisma.courseSection.deleteMany({ where: { courseId } });
    if (sections.length === 0) return [];
    await this.prisma.courseSection.createMany({
      data: sections.map((section, index) => ({
        courseId,
        sectionKey: section.sectionKey,
        title: section.title,
        description: section.description,
        keyTopics: section.keyTopics,
        order: index,
        estimatedMinutes: section.estimatedMinutes ?? DEFAULT_MINUTES,
        status: 'PENDING' as const,
      })),
    });
    return this.listByCourse(courseId);
  }

  public async listByCourse(courseId: string): Promise<CourseSection[]> {
    const rows = (await this.prisma.courseSection.findMany({
      where: { courseId },
      orderBy: { order: 'asc' },
    })) as unknown as RawSectionRow[];
    return rows.map((row) => this.toSection(row));
  }

  public async findByKey(courseId: string, sectionKey: string): Promise<CourseSection | null> {
    const row = (await this.prisma.courseSection.findUnique({
      where: { courseId_sectionKey: { courseId, sectionKey } },
    })) as unknown as RawSectionRow | null;
    return row ? this.toSection(row) : null;
  }

  public async saveContent(params: SaveContentParams): Promise<CourseSection> {
    const row = (await this.prisma.courseSection.update({
      where: { courseId_sectionKey: { courseId: params.courseId, sectionKey: params.sectionKey } },
      data: {
        content: params.content,
        status: params.status ?? 'GENERATED',
      },
    })) as unknown as RawSectionRow;
    return this.toSection(row);
  }

  public async updateStatus(
    courseId: string,
    sectionKey: string,
    status: SectionStatus,
  ): Promise<CourseSection> {
    const row = (await this.prisma.courseSection.update({
      where: { courseId_sectionKey: { courseId, sectionKey } },
      data: { status },
    })) as unknown as RawSectionRow;
    return this.toSection(row);
  }

  public async countNotValidated(courseId: string): Promise<number> {
    return this.prisma.courseSection.count({
      where: { courseId, status: { not: 'VALIDATED' } },
    });
  }
}
