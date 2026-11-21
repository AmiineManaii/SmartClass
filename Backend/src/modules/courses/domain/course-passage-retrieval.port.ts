export interface CoursePassageHit {
  passageId: string;
  title: string;
  content: string;
  /** Cosine similarity in `[0, 1]` — higher is closer. */
  score: number;
}

/**
 * Vector retrieval scoped to ONE course and its author, so the tutor can
 * only ground its answer in the teacher's validated passages (RG27: local
 * embeddings only, no third-party LLM).
 */
export interface CoursePassageRetrievalPort {
  search(input: {
    courseId: string;
    authorId: string;
    query: string;
    k?: number;
  }): Promise<CoursePassageHit[]>;
}
