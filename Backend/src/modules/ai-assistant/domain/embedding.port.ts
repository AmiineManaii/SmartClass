/**
 * Embeds text into a fixed-size vector for semantic memory search.
 * Implementations talk to a self-hosted model (RG27: no third-party LLM
 * APIs). EmbeddingGemma produces 768-dim vectors, matching the
 * `course_passages.embedding vector(768)` column.
 */
export const EMBEDDING_DIMENSION = 768;

export interface EmbeddingStatus {
  available: boolean;
  model: string;
  latencyMs: number | null;
}

export interface EmbeddingPort {
  /** Embeds `text`; resolves with a vector of length EMBEDDING_DIMENSION. */
  embed(text: string): Promise<number[]>;
  /** Cheap liveness probe (never throws). */
  checkHealth(): Promise<EmbeddingStatus>;
}
