import { getEnv } from '../../../config/env.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import {
  EMBEDDING_DIMENSION,
  type EmbeddingPort,
  type EmbeddingStatus,
} from '../domain/embedding.port.js';

/** Ollama /api/embeddings response body. */
interface OllamaEmbeddingResponse {
  embedding?: number[];
  error?: string;
}

/**
 * Embeddings from a self-hosted Ollama server (RG27: no third-party LLM
 * APIs). Uses the native `/api/embeddings` endpoint, which is the most
 * broadly supported across Ollama models including EmbeddingGemma.
 */
export class OllamaEmbeddingAdapter implements EmbeddingPort {
  public async embed(text: string): Promise<number[]> {
    const env = getEnv();
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), env.EMBEDDING_TIMEOUT_MS);
    try {
      const response = await fetch(`${env.EMBEDDING_BASE_URL}/api/embeddings`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model: env.EMBEDDING_MODEL, prompt: text }),
        signal: controller.signal,
      });
      if (!response.ok) {
        throw new Error(`Ollama embeddings HTTP ${response.status}`);
      }
      const body = (await response.json().catch(() => null)) as OllamaEmbeddingResponse | null;
      const vector = body?.embedding;
      if (!Array.isArray(vector) || vector.length !== EMBEDDING_DIMENSION) {
        throw new Error(
          `Ollama returned embedding of dim ${Array.isArray(vector) ? vector.length : 'none'}, expected ${EMBEDDING_DIMENSION}`,
        );
      }
      return vector.map((n) => (typeof n === 'number' ? n : 0));
    } finally {
      clearTimeout(timer);
    }
  }

  public async checkHealth(): Promise<EmbeddingStatus> {
    const env = getEnv();
    const startedAt = Date.now();
    try {
      const vector = await this.embed('ping');
      return {
        available: vector.length === EMBEDDING_DIMENSION,
        model: env.EMBEDDING_MODEL,
        latencyMs: Date.now() - startedAt,
      };
    } catch (error) {
      logger.debug({ err: error }, 'Embedding server not reachable');
      return { available: false, model: env.EMBEDDING_MODEL, latencyMs: null };
    }
  }
}
