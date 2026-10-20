/** One remembered chunk of a teacher's previously validated content. */
export interface StoredPassage {
  id: string;
  authorId: string;
  courseId: string | null;
  sectionId: string | null;
  subject: string | null;
  title: string;
  content: string;
}

/** A memory hit returned for context injection, with its similarity. */
export interface MemoryHit extends StoredPassage {
  /** Cosine similarity in [0, 1]; higher = more relevant. */
  similarity: number;
}

/**
 * Vector memory of a teacher's validated course content (pgvector).
 * Strictly scoped by author so one teacher's content is never surfaced to
 * another (no cross-tenant leakage).
 */
export interface SectionMemoryPort {
  /**
   * Stores an embedded passage. The adapter embeds `content` internally
   * (or accepts a precomputed vector — implementation detail) and writes
   * it to `course_passages`.
   */
  store(passage: {
    authorId: string;
    courseId?: string | null;
    sectionId?: string | null;
    subject?: string | null;
    title: string;
    content: string;
  }): Promise<StoredPassage>;

  /**
   * Returns the top-`k` most similar passages authored by `authorId`.
   * `queryVector` must be produced by the same embedding model.
   * An optional `subject` biases results toward the same subject.
   */
  search(args: {
    authorId: string;
    queryVector: number[];
    k?: number;
    subject?: string | null;
  }): Promise<MemoryHit[]>;
}
