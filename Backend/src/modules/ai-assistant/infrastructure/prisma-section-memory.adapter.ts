import { randomUUID } from 'node:crypto';
import type { Pool } from 'pg';
import { getPgPool } from '../../../shared/infrastructure/prisma.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type { EmbeddingPort } from '../domain/embedding.port.js';
import type {
  MemoryHit,
  SectionMemoryPort,
  StoredPassage,
} from '../domain/section-memory.port.js';

/** Row shape returned by the parameterized vector queries below. */
interface PassageRow {
  id: string;
  author_id: string;
  course_id: string | null;
  section_id: string | null;
  subject: string | null;
  title: string;
  content: string;
  similarity: number;
}

const toStored = (row: PassageRow): StoredPassage => ({
  id: row.id,
  authorId: row.author_id,
  courseId: row.course_id,
  sectionId: row.section_id,
  subject: row.subject,
  title: row.title,
  content: row.content,
});

/** Formats a vector as a pgvector literal: '[0.1,0.2,...]'. */
const toVectorLiteral = (vector: number[]): string =>
  `[${vector.map((n) => (Number.isFinite(n) ? n : 0)).join(',')}]`;

/**
 * pgvector-backed section memory. All SQL is parameterized ($1, $2 …) —
 * never concatenated — and every read/write is scoped by `author_id` so
 * one teacher's validated content is never surfaced to another.
 *
 * `embedding` is an `Unsupported("vector(768)")` column: Prisma cannot
 * type it, hence the raw `pg` queries here (documented seam, BACKEND §9).
 */
export class PrismaSectionMemoryAdapter implements SectionMemoryPort {
  constructor(
    private readonly pool: () => Pool = getPgPool,
    private readonly embedder: EmbeddingPort,
  ) {}

  public async store(passage: {
    authorId: string;
    courseId?: string | null;
    sectionId?: string | null;
    subject?: string | null;
    title: string;
    content: string;
  }): Promise<StoredPassage> {
    const vector = await this.embedder.embed(passage.content);
    const id = randomUUID();
    const result = await this.pool().query(
      `INSERT INTO course_passages
         (id, author_id, course_id, section_id, subject, title, content, kind, embedding, created_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, 'SECTION', $8::vector, now())
       RETURNING id, author_id, course_id, section_id, subject, title, content`,
      [
        id,
        passage.authorId,
        passage.courseId ?? null,
        passage.sectionId ?? null,
        passage.subject ?? null,
        passage.title,
        passage.content,
        toVectorLiteral(vector),
      ],
    );
    const row = result.rows[0] as PassageRow | undefined;
    if (!row) throw new Error('Failed to insert course passage');
    logger.debug({ passageId: id }, 'Stored course passage in vector memory');
    return toStored(row);
  }

  public async search(args: {
    authorId: string;
    queryVector: number[];
    k?: number;
    subject?: string | null;
  }): Promise<MemoryHit[]> {
    const k = Math.max(1, Math.min(args.k ?? 3, 10));
    const literal = toVectorLiteral(args.queryVector);
    // Cosine distance (`<=>`) → similarity = 1 - distance. The subject
    // preference is a soft tie-breaker: passages on the same subject sort
    // first when similarities are close, without ever crossing authors.
    const result = await this.pool().query(
      `SELECT id, author_id, course_id, section_id, subject, title, content,
              (1 - (embedding <=> $2::vector)) AS similarity
         FROM course_passages
        WHERE author_id = $1
        ORDER BY
          CASE WHEN $3::text IS NOT NULL AND subject = $3::text THEN 0 ELSE 1 END,
          embedding <=> $2::vector
        LIMIT $4`,
      [args.authorId, literal, args.subject ?? null, k],
    );
    return result.rows.map((row) => {
      const typed = row as PassageRow;
      return {
        ...toStored(typed),
        similarity: Number.isFinite(typed.similarity) ? Number(typed.similarity) : 0,
      };
    });
  }
}
