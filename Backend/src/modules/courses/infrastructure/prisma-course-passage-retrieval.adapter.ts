import type { Pool } from 'pg';
import { getPgPool } from '../../../shared/infrastructure/prisma.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type { EmbeddingPort } from '../../ai-assistant/index.js';
import { embedWithFallback } from '../../ai-assistant/index.js';
import type {
  CoursePassageHit,
  CoursePassageRetrievalPort,
} from '../domain/course-passage-retrieval.port.js';

const toVectorLiteral = (vector: number[]): string =>
  `[${vector.map((n) => (Number.isFinite(n) ? n : 0)).join(',')}]`;

interface PassageRow {
  id: string;
  section_id: string | null;
  title: string;
  content: string;
  similarity: number;
}

/**
 * pgvector retrieval over `course_passages`, doubly scoped by `course_id`
 * and `author_id`: a student can never pull passages from another teacher
 * into the tutor context. All SQL is parameterized (`$1`, `$2`…).
 */
export class PrismaCoursePassageRetrievalAdapter
  implements CoursePassageRetrievalPort
{
  constructor(
    private readonly pool: () => Pool = getPgPool,
    private readonly embedder?: EmbeddingPort,
  ) {}

  public async search(input: {
    courseId: string;
    authorId: string;
    query: string;
    k?: number;
  }): Promise<CoursePassageHit[]> {
    const k = Math.max(1, Math.min(input.k ?? 5, 12));
    try {
      const queryVector = await embedWithFallback(this.embedder, input.query);
      const result = await this.pool().query(
        `SELECT id, section_id, title, content,
                (1 - (embedding <=> $3::vector)) AS similarity
           FROM course_passages
          WHERE course_id = $1 AND author_id = $2
          ORDER BY embedding <=> $3::vector
          LIMIT $4`,
        [input.courseId, input.authorId, toVectorLiteral(queryVector), k],
      );
      return (result.rows as PassageRow[]).map((row) => ({
        passageId: row.section_id ?? row.id,
        title: row.title,
        content: row.content,
        score: Number.isFinite(row.similarity) ? Number(row.similarity) : 0,
      }));
    } catch (error) {
      logger.debug({ err: error, courseId: input.courseId }, 'Course passage retrieval unavailable');
      return [];
    }
  }
}
