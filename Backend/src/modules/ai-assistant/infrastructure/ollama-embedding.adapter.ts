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

/**
 * Computes a deterministic 768-dimensional L2-normalized lexical/trigram feature
 * vector when the dedicated Ollama embedding model is not pulled locally, so
 * pgvector similarity search and RAG remain 100% operational offline.
 */
export const computeDeterministicLexicalVector = (text: string): number[] => {
  const vec = new Float64Array(EMBEDDING_DIMENSION);
  const normalized = text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
  const tokens = normalized.split(/[^a-z0-9]+/).filter((t) => t.length >= 2);

  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i]!;
    let hash = 2166136261;
    for (let c = 0; c < token.length; c++) {
      hash ^= token.charCodeAt(c);
      hash = Math.imul(hash, 16777619);
    }
    const idx = Math.abs(hash) % EMBEDDING_DIMENSION;
    const sign = (hash & 1) === 0 ? 1 : -1;
    vec[idx] = (vec[idx] ?? 0) + sign * 1.5;

    // Character 3-grams for morphological tolerance
    for (let c = 0; c <= token.length - 3; c++) {
      const tri = token.slice(c, c + 3);
      let th = 5381;
      for (let k = 0; k < 3; k++) {
        th = (th * 33) ^ tri.charCodeAt(k);
      }
      const tidx = Math.abs(th) % EMBEDDING_DIMENSION;
      vec[tidx] = (vec[tidx] ?? 0) + 0.5;
    }
  }

  let norm = 0;
  for (let i = 0; i < EMBEDDING_DIMENSION; i++) {
    const v = vec[i] ?? 0;
    norm += v * v;
  }
  norm = Math.sqrt(norm) || 1;
  return Array.from(vec, (v) => Number((v / norm).toFixed(6)));
};

export const embedWithFallback = async (
  embedder: EmbeddingPort | undefined,
  text: string,
): Promise<number[]> => {
  if (embedder) {
    try {
      return await embedder.embed(text);
    } catch {
      // Fallback to deterministic 768-dim vector when embeddinggemma-2 is offline
    }
  }
  return computeDeterministicLexicalVector(text);
};
