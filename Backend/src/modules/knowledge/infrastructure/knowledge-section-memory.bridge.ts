import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type {
  MemoryHit,
  SectionMemoryPort,
  StoredPassage,
} from '../../ai-assistant/domain/section-memory.port.js';
import type { KnowledgeIndexerPort } from '../domain/knowledge-indexer.port.js';
import type { KnowledgeRepositoryPort } from '../domain/knowledge-repository.port.js';

/**
 * Bridges legacy `SectionMemoryPort` (used when validating or generating
 * modular course sections) onto the unified SmartClass Knowledge Engine
 * while falling back cleanly to `legacyFallback` when unified returns 0 hits.
 */
export class KnowledgeSectionMemoryBridge implements SectionMemoryPort {
  constructor(
    private readonly indexer: KnowledgeIndexerPort,
    private readonly repository: KnowledgeRepositoryPort,
    private readonly legacyFallback?: SectionMemoryPort,
  ) {}

  public async store(passage: {
    authorId: string;
    courseId?: string | null;
    sectionId?: string | null;
    subject?: string | null;
    title: string;
    content: string;
  }): Promise<StoredPassage> {
    const sourceId =
      passage.sectionId ?? passage.courseId ?? `${passage.authorId}:${passage.title}`;
    const doc = await this.indexer.indexNow({
      sourceType: 'COURSE_SECTION',
      sourceId,
      authorId: passage.authorId,
      title: passage.title,
      subject: passage.subject ?? null,
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'VERIFIED',
      content: passage.content,
      metadata: {
        ...(passage.courseId ? { courseId: passage.courseId } : {}),
        ...(passage.sectionId ? { sectionId: passage.sectionId } : {}),
      },
    });

    if (this.legacyFallback) {
      await this.legacyFallback.store(passage).catch(() => undefined);
    }

    return {
      id: doc?.id ?? sourceId,
      authorId: passage.authorId,
      courseId: passage.courseId ?? null,
      sectionId: passage.sectionId ?? null,
      subject: passage.subject ?? null,
      title: passage.title,
      content: passage.content,
    };
  }

  public async search(args: {
    authorId: string;
    queryVector: number[];
    k?: number;
    subject?: string | null;
  }): Promise<MemoryHit[]> {
    const k = Math.max(1, args.k ?? 3);
    const candidates = await this.repository.searchVectorCandidates({
      scope: {
        mode: 'AUTHOR_PRIVATE',
        authorId: args.authorId,
        enrolledClassGroupIds: [],
        allowedVisibilities: ['PRIVATE_AUTHOR', 'CLASS_PUBLISHED', 'INSTITUTION_SHARED'],
        allowedTrustTiers: ['VERIFIED'],
      },
      queryVector: args.queryVector,
      filters: {
        ...(args.subject ? { subject: args.subject } : {}),
        trustTiers: ['VERIFIED'],
      },
      limit: k,
    });

    if (candidates.length > 0) {
      return candidates.slice(0, k).map((c) => ({
        id: c.chunkId,
        authorId: args.authorId,
        courseId: typeof c.metadata.courseId === 'string' ? c.metadata.courseId : null,
        sectionId: typeof c.metadata.sectionId === 'string' ? c.metadata.sectionId : c.sourceId,
        subject: c.subject,
        title: c.sectionTitle ?? c.title,
        content: c.content,
        similarity: Number(c.vectorSimilarity.toFixed(4)),
      }));
    }

    if (this.legacyFallback) {
      return this.legacyFallback.search(args);
    }

    const legacy = await getPrismaClient().coursePassage.findMany({
      where: { authorId: args.authorId },
      take: k,
      orderBy: { createdAt: 'desc' },
    });
    return legacy.map((row) => ({
      id: row.id,
      authorId: row.authorId,
      courseId: row.courseId,
      sectionId: row.sectionId,
      subject: row.subject,
      title: row.title,
      content: row.content,
      similarity: 0.5,
    }));
  }
}
