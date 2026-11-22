import { getEnv } from '../../../config/env.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type {
  KnowledgeDocumentEntity,
  KnowledgeIndexInput,
} from '../domain/knowledge-document.entity.js';
import { KNOWLEDGE_EMBEDDING_DIMENSION, type KnowledgeEmbeddingPort } from '../domain/knowledge-embedding.port.js';
import type { KnowledgeRepositoryPort } from '../domain/knowledge-repository.port.js';
import {
  chunkKnowledgeInput,
  computeDocumentContentHash,
} from '../domain/structure-chunker.js';

export class IndexKnowledgeDocumentUseCase {
  constructor(
    private readonly repository: KnowledgeRepositoryPort,
    private readonly embedding: KnowledgeEmbeddingPort,
  ) {}

  public async execute(input: KnowledgeIndexInput): Promise<KnowledgeDocumentEntity | null> {
    const chunks = chunkKnowledgeInput(input);
    const contentHash = computeDocumentContentHash(input, chunks);
    const existing = await this.repository.findBySource(input.sourceType, input.sourceId);

    const sameClassGroups =
      existing !== null &&
      existing.classGroupIds.length === (input.classGroupIds?.length ?? 0) &&
      existing.classGroupIds.every((id, idx) => id === (input.classGroupIds ?? [])[idx]);

    if (
      existing &&
      !input.force &&
      existing.contentHash === contentHash &&
      existing.indexStatus === 'INDEXED'
    ) {
      if (
        existing.visibility !== input.visibility ||
        existing.trustTier !== input.trustTier ||
        !sameClassGroups
      ) {
        return this.repository.updateLifecycleBySource({
          sourceType: input.sourceType,
          sourceId: input.sourceId,
          visibility: input.visibility,
          trustTier: input.trustTier,
          classGroupIds: input.classGroupIds ?? [],
        });
      }
      return existing;
    }

    const env = getEnv();
    const classGroupIds = [...new Set(input.classGroupIds ?? [])];

    if (chunks.length === 0) {
      return this.repository.upsertDocumentAndChunks({
        sourceType: input.sourceType,
        sourceId: input.sourceId,
        authorId: input.authorId,
        title: input.title,
        subject: input.subject ?? null,
        language: input.language ?? 'fr',
        visibility: input.visibility,
        trustTier: input.trustTier,
        classGroupIds,
        contentHash,
        indexStatus: 'INDEXED',
        embeddingModel: env.EMBEDDING_MODEL,
        embeddingDims: KNOWLEDGE_EMBEDDING_DIMENSION,
        errorMessage: null,
        indexedAt: new Date(),
        metadata: input.metadata ?? {},
        chunks: [],
      });
    }

    const textsToEmbed = chunks.map((chunk) => `${chunk.contextHeader}\n${chunk.content}`);
    let vectors: Array<number[] | null> = [];
    let indexStatus: 'INDEXED' | 'PENDING_EMBEDDING' = 'INDEXED';
    let errorMessage: string | null = null;
    let indexedAt: Date | null = new Date();

    try {
      const embedded = await this.embedding.embedBatch(textsToEmbed);
      vectors = embedded;
    } catch (err) {
      // Honest explicit fallback: persist chunks with NULL vector and mark
      // PENDING_EMBEDDING so FTS retrieval works immediately and recovery
      // will generate CPU embeddings once Ollama comes back online.
      indexStatus = 'PENDING_EMBEDDING';
      errorMessage = err instanceof Error ? err.message : 'CPU embedding runtime unavailable';
      indexedAt = null;
      vectors = chunks.map(() => null);
      logger.warn(
        {
          sourceType: input.sourceType,
          sourceId: input.sourceId,
          chunkCount: chunks.length,
          reason: errorMessage,
        },
        'Knowledge indexing persisted chunks in PENDING_EMBEDDING state (no fake vectors stored)',
      );
    }

    return this.repository.upsertDocumentAndChunks({
      sourceType: input.sourceType,
      sourceId: input.sourceId,
      authorId: input.authorId,
      title: input.title,
      subject: input.subject ?? null,
      language: input.language ?? 'fr',
      visibility: input.visibility,
      trustTier: input.trustTier,
      classGroupIds,
      contentHash,
      indexStatus,
      embeddingModel: indexStatus === 'INDEXED' ? env.EMBEDDING_MODEL : null,
      embeddingDims: KNOWLEDGE_EMBEDDING_DIMENSION,
      errorMessage,
      indexedAt,
      metadata: input.metadata ?? {},
      chunks: chunks.map((chunk, idx) => ({
        ...chunk,
        embedding: vectors[idx] ?? null,
      })),
    });
  }
}
