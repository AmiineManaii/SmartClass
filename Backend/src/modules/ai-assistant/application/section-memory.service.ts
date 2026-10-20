import { logger } from '../../../shared/infrastructure/logger.js';
import type { EmbeddingPort } from '../domain/embedding.port.js';
import type { SectionMemoryPort } from '../domain/section-memory.port.js';
import type { SectionMemoryContext } from '../domain/course-prompt.js';

export interface RememberPassageInput {
  authorId: string;
  courseId?: string | null;
  sectionId?: string | null;
  subject?: string | null;
  title: string;
  content: string;
}

/**
 * Vector-memory facade for the section flows.
 *
 * Every operation degrades gracefully: when the embedding server or
 * pgvector is unreachable, `recall` resolves to `[]` and `remember`
 * resolves to void — with a warning logged. Generation and validation
 * must never be blocked by the memory subsystem.
 */
export class SectionMemoryService {
  constructor(
    private readonly memory: SectionMemoryPort,
    private readonly embedder: EmbeddingPort,
  ) {}

  /** Top-k similar validated passages for `query`, or [] when unavailable. */
  public async recall(args: {
    authorId: string;
    subject?: string | null;
    query: string;
    k?: number;
  }): Promise<SectionMemoryContext[]> {
    if (!args.query.trim()) return [];
    try {
      const vector = await this.embedder.embed(args.query);
      const hits = await this.memory.search({
        authorId: args.authorId,
        queryVector: vector,
        k: args.k ?? 3,
        subject: args.subject ?? null,
      });
      return hits.map((hit) => ({
        title: hit.title,
        content: hit.content,
        similarity: hit.similarity,
      }));
    } catch (error) {
      logger.warn({ err: error }, 'Section memory recall failed; continuing without memory');
      return [];
    }
  }

  /** Persists a validated passage (never throws). */
  public async remember(input: RememberPassageInput): Promise<void> {
    try {
      await this.memory.store(input);
    } catch (error) {
      logger.warn({ err: error }, 'Failed to store passage in section memory');
    }
  }
}
