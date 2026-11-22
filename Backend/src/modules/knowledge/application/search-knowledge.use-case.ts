import { logger } from '../../../shared/infrastructure/logger.js';
import type { ClassMembershipPort } from '../domain/class-membership.port.js';
import { fuseAndDiversifyRrfMmr, type FtsCandidate, type VectorCandidate } from '../domain/hybrid-ranker.js';
import type {
  KnowledgeSearchMode,
  KnowledgeSearchResult,
} from '../domain/knowledge-document.entity.js';
import type { KnowledgeEmbeddingPort } from '../domain/knowledge-embedding.port.js';
import { resolveRetrievalScope } from '../domain/knowledge-policy.js';
import type { KnowledgeRepositoryPort } from '../domain/knowledge-repository.port.js';
import type {
  KnowledgeRetrievalPort,
  KnowledgeSearchRequest,
} from '../domain/knowledge-retrieval.port.js';
import { computeSha256 } from '../domain/structure-chunker.js';

export class SearchKnowledgeUseCase implements KnowledgeRetrievalPort {
  constructor(
    private readonly repository: KnowledgeRepositoryPort,
    private readonly embedding: KnowledgeEmbeddingPort,
    private readonly classMembership: ClassMembershipPort,
  ) {}

  public async search(request: KnowledgeSearchRequest): Promise<KnowledgeSearchResult> {
    const startedAt = Date.now();
    const k = Math.max(1, Math.min(20, request.k ?? 6));
    const trimmedQuery = request.query.trim();

    if (!trimmedQuery) {
      return {
        query: '',
        searchMode: 'FTS_ONLY',
        degradedReason: null,
        embeddingLatencyMs: null,
        searchLatencyMs: 0,
        totalLatencyMs: Date.now() - startedAt,
        candidateCount: 0,
        hits: [],
      };
    }

    const enrolledClassGroupIds =
      request.actor.role === 'STUDENT'
        ? await this.classMembership.listEnrolledClassGroupIds(request.actor.id)
        : [];

    const scope = resolveRetrievalScope(request.actor, enrolledClassGroupIds, request.filters);

    if (scope.mode === 'EMPTY') {
      const totalMs = Date.now() - startedAt;
      await this.safeLog({
        userId: request.actor.id,
        userRole: request.actor.role,
        query: trimmedQuery,
        queryHash: computeSha256(trimmedQuery),
        searchMode: 'FTS_ONLY',
        degradedReason: null,
        filters: (request.filters ?? {}) as Record<string, unknown>,
        candidateCount: 0,
        returnedCount: 0,
        topScore: null,
        embeddingLatencyMs: null,
        searchLatencyMs: 0,
        totalLatencyMs: totalMs,
      });
      return {
        query: trimmedQuery,
        searchMode: 'FTS_ONLY',
        degradedReason: null,
        embeddingLatencyMs: null,
        searchLatencyMs: 0,
        totalLatencyMs: totalMs,
        candidateCount: 0,
        hits: [],
      };
    }

    const candidateLimit = Math.min(40, Math.max(16, k * 4));
    let searchMode: KnowledgeSearchMode = request.preferredMode ?? 'HYBRID';
    let degradedReason: string | null = null;
    let embeddingLatencyMs: number | null = null;
    let queryVector: number[] | null = null;

    if (searchMode !== 'FTS_ONLY') {
      const embStart = Date.now();
      try {
        queryVector = await this.embedding.embedOne(trimmedQuery);
        embeddingLatencyMs = Date.now() - embStart;
      } catch (err) {
        embeddingLatencyMs = Date.now() - embStart;
        searchMode = 'FTS_ONLY';
        degradedReason =
          err instanceof Error
            ? `Embedding runtime unavailable (${err.message}); degraded explicitly to PostgreSQL FTS`
            : 'Embedding runtime unavailable; degraded explicitly to PostgreSQL FTS';
      }
    }

    const dbStart = Date.now();
    let vectorCandidates: VectorCandidate[] = [];
    let ftsCandidates: FtsCandidate[] = [];

    if (searchMode === 'HYBRID' && queryVector) {
      [vectorCandidates, ftsCandidates] = await Promise.all([
        this.repository.searchVectorCandidates({
          scope,
          queryVector,
          filters: request.filters,
          limit: candidateLimit,
        }),
        this.repository.searchFtsCandidates({
          scope,
          query: trimmedQuery,
          filters: request.filters,
          limit: candidateLimit,
        }),
      ]);
      // If chunks exist only without embeddings (PENDING_EMBEDDING), vectorCandidates may be empty
      // while ftsCandidates has results; if NEITHER ran vector matches and there were no embedded chunks,
      // stay HYBRID unless embedding itself failed, OR fuse clean results.
    } else if (searchMode === 'VECTOR_ONLY' && queryVector) {
      vectorCandidates = await this.repository.searchVectorCandidates({
        scope,
        queryVector,
        filters: request.filters,
        limit: candidateLimit,
      });
    } else {
      ftsCandidates = await this.repository.searchFtsCandidates({
        scope,
        query: trimmedQuery,
        filters: request.filters,
        limit: candidateLimit,
      });
    }
    const searchLatencyMs = Date.now() - dbStart;

    const hits = fuseAndDiversifyRrfMmr(vectorCandidates, ftsCandidates, {
      k,
      vectorWeight: searchMode === 'FTS_ONLY' ? 0 : searchMode === 'VECTOR_ONLY' ? 1 : 0.65,
      ftsWeight: searchMode === 'VECTOR_ONLY' ? 0 : searchMode === 'FTS_ONLY' ? 1 : 0.35,
    });

    const uniqueCandidateIds = new Set([
      ...vectorCandidates.map((c) => c.chunkId),
      ...ftsCandidates.map((c) => c.chunkId),
    ]);
    const totalLatencyMs = Date.now() - startedAt;

    await this.safeLog({
      userId: request.actor.id,
      userRole: request.actor.role,
      query: trimmedQuery,
      queryHash: computeSha256(trimmedQuery),
      searchMode,
      degradedReason,
      filters: (request.filters ?? {}) as Record<string, unknown>,
      candidateCount: uniqueCandidateIds.size,
      returnedCount: hits.length,
      topScore: hits[0]?.score ?? null,
      embeddingLatencyMs,
      searchLatencyMs,
      totalLatencyMs,
    });

    return {
      query: trimmedQuery,
      searchMode,
      degradedReason,
      embeddingLatencyMs,
      searchLatencyMs,
      totalLatencyMs,
      candidateCount: uniqueCandidateIds.size,
      hits,
    };
  }

  private async safeLog(params: Parameters<KnowledgeRepositoryPort['logRetrieval']>[0]): Promise<void> {
    try {
      await this.repository.logRetrieval(params);
    } catch (err) {
      logger.debug({ err }, 'Failed writing knowledge_retrieval_logs telemetry');
    }
  }
}
