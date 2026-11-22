export const KNOWLEDGE_EMBEDDING_DIMENSION = 768;

export interface KnowledgeEmbeddingHealth {
  available: boolean;
  model: string;
  numGpu: number;
  dimension: number;
  latencyMs: number | null;
  runtime: 'cpu' | 'gpu';
}

export interface KnowledgeEmbeddingPort {
  embedOne(text: string): Promise<number[]>;
  embedBatch(texts: string[]): Promise<number[][]>;
  checkHealth(): Promise<KnowledgeEmbeddingHealth>;
}
