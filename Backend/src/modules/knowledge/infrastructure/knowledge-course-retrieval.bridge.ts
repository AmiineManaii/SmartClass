import type {
  CoursePassageHit,
  CoursePassageRetrievalPort,
} from '../../courses/domain/course-passage-retrieval.port.js';
import type { KnowledgeRetrievalPort } from '../domain/knowledge-retrieval.port.js';

/**
 * Bridges `CoursePassageRetrievalPort` (used by `AskCourseTutorUseCase`)
 * onto the unified SmartClass Knowledge Engine scoped strictly to the target
 * `courseId`, falling back to legacy `course_passages` if the course has not
 * been backfilled into `knowledge_documents` yet.
 */
export class KnowledgeCourseRetrievalBridge implements CoursePassageRetrievalPort {
  constructor(
    private readonly retrieval: KnowledgeRetrievalPort,
    private readonly legacyFallback?: CoursePassageRetrievalPort,
  ) {}

  public async search(input: {
    courseId: string;
    authorId: string;
    query: string;
    k?: number;
  }): Promise<CoursePassageHit[]> {
    const k = Math.max(1, input.k ?? 6);
    const res = await this.retrieval.search({
      actor: { id: input.authorId, role: 'TEACHER' },
      query: input.query,
      k,
      filters: {
        sourceTypes: ['COURSE', 'COURSE_SECTION'],
        sourceIds: [input.courseId],
      },
    });

    if (res.hits.length > 0) {
      return res.hits.map((hit) => ({
        passageId: hit.chunkId,
        title: hit.sectionTitle ?? hit.title,
        content: hit.content,
        score: hit.score,
      }));
    }

    if (this.legacyFallback) {
      return this.legacyFallback.search(input);
    }

    return [];
  }
}
