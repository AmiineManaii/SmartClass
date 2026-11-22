import { getEnv } from '../../../config/env.js';
import { EmbeddingServiceUnavailableError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import {
  KNOWLEDGE_EMBEDDING_DIMENSION,
  type KnowledgeEmbeddingHealth,
  type KnowledgeEmbeddingPort,
} from '../domain/knowledge-embedding.port.js';

interface OllamaEmbedApiResponse {
  embeddings?: number[][];
  embedding?: number[];
  error?: string;
}

const MAX_BATCH_SIZE = 16;

/**
 * Self-hosted Ollama CPU embedding adapter (`num_gpu: 0`).
 * Never uses deterministic lexical hash vectors as substitutes for semantic
 * embeddings; throws `EmbeddingServiceUnavailableError` so callers explicitly
 * degrade to PostgreSQL Full-Text Search (`FTS_ONLY`) or mark chunks `PENDING_EMBEDDING`.
 */
export class OllamaCpuEmbeddingAdapter implements KnowledgeEmbeddingPort {
  public async embedOne(text: string): Promise<number[]> {
    const [vec] = await this.embedBatch([text]);
    if (!vec) {
      throw new EmbeddingServiceUnavailableError('Ollama returned an empty embedding batch');
    }
    return vec;
  }

  public async embedBatch(texts: string[]): Promise<number[][]> {
    if (texts.length === 0) return [];
    const env = getEnv();
    const baseUrl = env.EMBEDDING_BASE_URL.replace(/\/+$/, '');
    const results: number[][] = [];

    for (let i = 0; i < texts.length; i += MAX_BATCH_SIZE) {
      const slice = texts.slice(i, i + MAX_BATCH_SIZE);
      const batchVecs = await this.requestBatch(
        baseUrl,
        env.EMBEDDING_MODEL,
        env.EMBEDDING_NUM_GPU,
        env.EMBEDDING_TIMEOUT_MS,
        slice,
      );
      results.push(...batchVecs);
    }

    return results;
  }

  public async checkHealth(): Promise<KnowledgeEmbeddingHealth> {
    const env = getEnv();
    const startedAt = Date.now();
    try {
      const vec = await this.embedOne('SmartClass knowledge embedding probe');
      return {
        available: vec.length === KNOWLEDGE_EMBEDDING_DIMENSION,
        model: env.EMBEDDING_MODEL,
        numGpu: env.EMBEDDING_NUM_GPU,
        dimension: vec.length,
        latencyMs: Date.now() - startedAt,
        runtime: env.EMBEDDING_NUM_GPU === 0 ? 'cpu' : 'gpu',
      };
    } catch (err) {
      logger.debug({ err }, 'Knowledge CPU embedding health check failed');
      return {
        available: false,
        model: env.EMBEDDING_MODEL,
        numGpu: env.EMBEDDING_NUM_GPU,
        dimension: KNOWLEDGE_EMBEDDING_DIMENSION,
        latencyMs: null,
        runtime: env.EMBEDDING_NUM_GPU === 0 ? 'cpu' : 'gpu',
      };
    }
  }

  private async requestBatch(
    baseUrl: string,
    model: string,
    numGpu: number,
    timeoutMs: number,
    inputs: string[],
  ): Promise<number[][]> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const response = await fetch(`${baseUrl}/api/embed`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model,
          input: inputs.length === 1 ? inputs[0] : inputs,
          truncate: true,
          options: { num_gpu: numGpu },
        }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const errBody = await response.text().catch(() => '');
        throw new EmbeddingServiceUnavailableError(
          `Ollama CPU embedding error (HTTP ${response.status})${errBody ? `: ${errBody.slice(0, 160)}` : ''}`,
        );
      }

      const body = (await response.json().catch(() => null)) as OllamaEmbedApiResponse | null;
      const rawVectors = Array.isArray(body?.embeddings)
        ? body.embeddings
        : Array.isArray(body?.embedding) && inputs.length === 1
          ? [body.embedding]
          : null;

      if (!rawVectors || rawVectors.length !== inputs.length) {
        throw new EmbeddingServiceUnavailableError(
          `Ollama returned ${rawVectors?.length ?? 0} embeddings for batch of ${inputs.length}`,
        );
      }

      return rawVectors.map((vec, idx) => {
        if (!Array.isArray(vec) || vec.length !== KNOWLEDGE_EMBEDDING_DIMENSION) {
          throw new EmbeddingServiceUnavailableError(
            `Embedding at index ${idx} has invalid dimension ${Array.isArray(vec) ? vec.length : 'none'}, expected ${KNOWLEDGE_EMBEDDING_DIMENSION}`,
          );
        }
        return vec.map((n) => (typeof n === 'number' && Number.isFinite(n) ? n : 0));
      });
    } catch (err) {
      if (err instanceof EmbeddingServiceUnavailableError) throw err;
      throw new EmbeddingServiceUnavailableError(
        `Local embedding runtime unreachable: ${err instanceof Error ? err.message : String(err)}`,
      );
    } finally {
      clearTimeout(timer);
    }
  }
}
