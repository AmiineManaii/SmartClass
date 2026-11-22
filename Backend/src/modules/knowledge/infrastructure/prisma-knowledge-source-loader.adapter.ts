import type { PrismaClient } from '@prisma/client';
import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type {
  KnowledgeIndexInput,
  KnowledgePackageInput,
  KnowledgeSourceType,
} from '../domain/knowledge-document.entity.js';
import type { KnowledgeSourceLoaderPort } from '../domain/knowledge-source-loader.port.js';

export class PrismaKnowledgeSourceLoaderAdapter implements KnowledgeSourceLoaderPort {
  constructor(private readonly prisma: PrismaClient = getPrismaClient()) {}

  public async loadAllCourses(authorId?: string): Promise<KnowledgeIndexInput[]> {
    const courses = await this.prisma.course.findMany({
      where: authorId ? { authorId } : undefined,
      include: { classGroups: { select: { id: true } } },
    });

    return courses.map((c) => {
      const isPublished = c.status === 'PUBLISHED';
      return {
        sourceType: 'COURSE' as const,
        sourceId: c.id,
        authorId: c.authorId,
        title: c.title,
        subject: c.subject,
        visibility: isPublished ? 'CLASS_PUBLISHED' : 'PRIVATE_AUTHOR',
        trustTier: isPublished ? 'VERIFIED' : 'DRAFT_AI',
        classGroupIds: c.classGroups.map((cg) => cg.id),
        content: c.content,
        metadata: {
          courseId: c.id,
          level: c.level,
          difficulty: c.difficulty,
          format: c.format,
        },
      };
    });
  }

  public async loadAllCourseSections(authorId?: string): Promise<KnowledgeIndexInput[]> {
    const sections = await this.prisma.courseSection.findMany({
      where: {
        content: { not: null },
        ...(authorId ? { course: { authorId } } : {}),
      },
      include: {
        course: {
          include: { classGroups: { select: { id: true } } },
        },
      },
    });

    return sections
      .filter((s) => Boolean(s.content?.trim()))
      .map((s) => {
        const isPublished = s.course.status === 'PUBLISHED';
        const isValidated = s.status === 'VALIDATED';
        return {
          sourceType: 'COURSE_SECTION' as const,
          sourceId: s.id,
          authorId: s.course.authorId,
          title: `${s.course.title} — ${s.title}`,
          subject: s.course.subject,
          visibility: isPublished ? 'CLASS_PUBLISHED' : 'PRIVATE_AUTHOR',
          trustTier: isValidated || isPublished ? 'VERIFIED' : 'DRAFT_AI',
          classGroupIds: s.course.classGroups.map((cg) => cg.id),
          content: s.content ?? '',
          metadata: {
            courseId: s.courseId,
            sectionKey: s.sectionKey,
            order: s.order,
          },
        };
      });
  }

  public async loadAllRecordings(authorId?: string): Promise<KnowledgeIndexInput[]> {
    const recordings = await this.prisma.recording.findMany({
      where: {
        status: { in: ['READY_FOR_REVIEW', 'APPROVED', 'PUBLISHED'] },
        ...(authorId
          ? {
              OR: [{ hostId: authorId }, { session: { hostId: authorId } }],
            }
          : {}),
      },
      include: {
        session: true,
        transcript: {
          include: { segments: { orderBy: { orderIndex: 'asc' } } },
        },
        slideFrames: { orderBy: { timestampSeconds: 'asc' } },
        chapters: { orderBy: { orderIndex: 'asc' } },
        lessonPackage: true,
      },
    });

    const out: KnowledgeIndexInput[] = [];
    for (const rec of recordings) {
      out.push(...this.mapRecordingToInputs(rec));
    }
    return out;
  }

  public async loadBySource(
    sourceType: KnowledgeSourceType,
    sourceId: string,
  ): Promise<KnowledgeIndexInput | null> {
    if (sourceType === 'COURSE') {
      const c = await this.prisma.course.findUnique({
        where: { id: sourceId },
        include: { classGroups: { select: { id: true } } },
      });
      if (!c) return null;
      const isPublished = c.status === 'PUBLISHED';
      return {
        sourceType: 'COURSE',
        sourceId: c.id,
        authorId: c.authorId,
        title: c.title,
        subject: c.subject,
        visibility: isPublished ? 'CLASS_PUBLISHED' : 'PRIVATE_AUTHOR',
        trustTier: isPublished ? 'VERIFIED' : 'DRAFT_AI',
        classGroupIds: c.classGroups.map((cg) => cg.id),
        content: c.content,
        metadata: { courseId: c.id, level: c.level, difficulty: c.difficulty, format: c.format },
      };
    }

    if (sourceType === 'COURSE_SECTION') {
      const s = await this.prisma.courseSection.findUnique({
        where: { id: sourceId },
        include: { course: { include: { classGroups: { select: { id: true } } } } },
      });
      if (!s || !s.content?.trim()) return null;
      const isPublished = s.course.status === 'PUBLISHED';
      const isValidated = s.status === 'VALIDATED';
      return {
        sourceType: 'COURSE_SECTION',
        sourceId: s.id,
        authorId: s.course.authorId,
        title: `${s.course.title} — ${s.title}`,
        subject: s.course.subject,
        visibility: isPublished ? 'CLASS_PUBLISHED' : 'PRIVATE_AUTHOR',
        trustTier: isValidated || isPublished ? 'VERIFIED' : 'DRAFT_AI',
        classGroupIds: s.course.classGroups.map((cg) => cg.id),
        content: s.content,
        metadata: { courseId: s.courseId, sectionKey: s.sectionKey, order: s.order },
      };
    }

    if (
      sourceType === 'LECTURE_TRANSCRIPT' ||
      sourceType === 'LECTURE_SLIDE' ||
      sourceType === 'LECTURE_PACKAGE' ||
      sourceType === 'RECORDING_SOURCE_DOC'
    ) {
      const rec = await this.prisma.recording.findUnique({
        where: { id: sourceId },
        include: {
          session: true,
          transcript: { include: { segments: { orderBy: { orderIndex: 'asc' } } } },
          slideFrames: { orderBy: { timestampSeconds: 'asc' } },
          chapters: { orderBy: { orderIndex: 'asc' } },
          lessonPackage: true,
        },
      });
      if (!rec) return null;
      return this.mapRecordingToInputs(rec).find((i) => i.sourceType === sourceType) ?? null;
    }

    return null;
  }

  private mapRecordingToInputs(rec: {
    id: string;
    sessionId: string;
    classGroupId: string;
    hostId: string | null;
    status: string;
    sourceDocTitle: string | null;
    sourceDocText: string | null;
    session: { hostId: string | null; title: string; subject: string | null };
    transcript: {
      language: string;
      fullText: string;
      segments: Array<{ startSeconds: number; endSeconds: number; text: string; speaker: string | null }>;
    } | null;
    slideFrames: Array<{
      timestampSeconds: number;
      ocrText: string;
      visualSummary: string;
      sourcePage: number | null;
    }>;
    chapters: Array<{
      orderIndex: number;
      title: string;
      summary: string;
      startSeconds: number;
      endSeconds: number;
      keyConcepts: unknown;
      sourcePage: number | null;
    }>;
    lessonPackage: {
      generalSummary: string;
      structuredNotes: string;
      keyConcepts: unknown;
      definitions: unknown;
      formulasAndRules: unknown;
      importantExamples: unknown;
      importantMoments: unknown;
    } | null;
  }): KnowledgeIndexInput[] {
    const ownerId = rec.hostId ?? rec.session.hostId;
    if (!ownerId) return [];
    const isPublished = rec.status === 'PUBLISHED';
    const isVerified = rec.status === 'APPROVED' || isPublished;
    const visibility = isPublished ? ('CLASS_PUBLISHED' as const) : ('PRIVATE_AUTHOR' as const);
    const trustTier = isVerified ? ('VERIFIED' as const) : ('DRAFT_AI' as const);
    const classGroupIds = isPublished ? [rec.classGroupId] : [];
    const baseMeta = {
      recordingId: rec.id,
      sessionId: rec.sessionId,
      classGroupId: rec.classGroupId,
    };

    const items: KnowledgeIndexInput[] = [];

    if (rec.transcript && (rec.transcript.segments.length > 0 || rec.transcript.fullText.trim())) {
      items.push({
        sourceType: 'LECTURE_TRANSCRIPT',
        sourceId: rec.id,
        authorId: ownerId,
        title: `${rec.session.title} — Transcription`,
        subject: rec.session.subject,
        language: rec.transcript.language || 'fr',
        visibility,
        trustTier,
        classGroupIds,
        content: rec.transcript.fullText,
        transcriptSegments: rec.transcript.segments,
        chapters: rec.chapters.map((ch) => ({
          orderIndex: ch.orderIndex,
          title: ch.title,
          summary: ch.summary,
          startSeconds: ch.startSeconds,
          endSeconds: ch.endSeconds,
          keyConcepts: Array.isArray(ch.keyConcepts) ? ch.keyConcepts.map(String) : [],
          sourcePage: ch.sourcePage,
        })),
        metadata: baseMeta,
      });
    }

    if (rec.slideFrames.length > 0) {
      items.push({
        sourceType: 'LECTURE_SLIDE',
        sourceId: rec.id,
        authorId: ownerId,
        title: `${rec.session.title} — Diapositives`,
        subject: rec.session.subject,
        language: rec.transcript?.language || 'fr',
        visibility,
        trustTier,
        classGroupIds,
        slides: rec.slideFrames.map((s, idx) => ({
          slideNumber: idx + 1,
          timestampSeconds: s.timestampSeconds,
          ocrText: s.ocrText,
          visualSummary: s.visualSummary,
          sourcePage: s.sourcePage,
        })),
        metadata: baseMeta,
      });
    }

    if (rec.lessonPackage) {
      const pkg = rec.lessonPackage;
      const lessonPackage: KnowledgePackageInput = {
        generalSummary: pkg.generalSummary,
        structuredNotes: pkg.structuredNotes,
        keyConcepts: Array.isArray(pkg.keyConcepts)
          ? (pkg.keyConcepts as KnowledgePackageInput['keyConcepts'])
          : [],
        definitions: Array.isArray(pkg.definitions)
          ? (pkg.definitions as KnowledgePackageInput['definitions'])
          : [],
        formulasAndRules: Array.isArray(pkg.formulasAndRules)
          ? pkg.formulasAndRules.map(String)
          : [],
        examples: Array.isArray(pkg.importantExamples)
          ? (pkg.importantExamples as KnowledgePackageInput['examples'])
          : [],
        importantMoments: Array.isArray(pkg.importantMoments)
          ? (pkg.importantMoments as KnowledgePackageInput['importantMoments'])
          : [],
      };
      items.push({
        sourceType: 'LECTURE_PACKAGE',
        sourceId: rec.id,
        authorId: ownerId,
        title: `${rec.session.title} — Synthèse & Notes`,
        subject: rec.session.subject,
        language: rec.transcript?.language || 'fr',
        visibility,
        trustTier,
        classGroupIds,
        lessonPackage,
        metadata: baseMeta,
      });
    }

    if (rec.sourceDocText && rec.sourceDocText.trim().length > 0) {
      items.push({
        sourceType: 'RECORDING_SOURCE_DOC',
        sourceId: rec.id,
        authorId: ownerId,
        title: rec.sourceDocTitle ?? `${rec.session.title} — Support de cours`,
        subject: rec.session.subject,
        visibility,
        trustTier,
        classGroupIds,
        content: rec.sourceDocText,
        metadata: baseMeta,
      });
    }

    return items;
  }
}
