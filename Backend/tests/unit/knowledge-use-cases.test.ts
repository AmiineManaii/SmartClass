import { describe, expect, it } from 'vitest';
import { ForbiddenError } from '../../src/shared/errors/app-error.js';
import { IndexKnowledgeDocumentUseCase } from '../../src/modules/knowledge/application/index-knowledge-document.use-case.js';
import { SearchKnowledgeUseCase } from '../../src/modules/knowledge/application/search-knowledge.use-case.js';
import { KnowledgeIndexQueueService } from '../../src/modules/knowledge/application/knowledge-index-queue.service.js';
import {
  DeleteKnowledgeDocumentUseCase,
} from '../../src/modules/knowledge/application/knowledge-management.use-cases.js';
import { KnowledgeCourseRetrievalBridge } from '../../src/modules/knowledge/infrastructure/knowledge-course-retrieval.bridge.js';
import type {
  KnowledgeDocumentEntity,
  KnowledgeIndexInput,
  KnowledgeSourceType,
} from '../../src/modules/knowledge/domain/knowledge-document.entity.js';
import type { KnowledgeEmbeddingPort } from '../../src/modules/knowledge/domain/knowledge-embedding.port.js';
import type {
  KnowledgeRepositoryPort,
  LogKnowledgeRetrievalParams,
  UpsertKnowledgeDocumentParams,
} from '../../src/modules/knowledge/domain/knowledge-repository.port.js';

class InMemoryKnowledgeRepository implements KnowledgeRepositoryPort {
  public docs = new Map<string, KnowledgeDocumentEntity>();
  public chunksByDoc = new Map<string, UpsertKnowledgeDocumentParams['chunks']>();
  public logs: LogKnowledgeRetrievalParams[] = [];
  private seq = 1;

  async ensureSchemaArtifacts(): Promise<void> {}

  async findBySource(sourceType: KnowledgeSourceType, sourceId: string) {
    for (const d of this.docs.values()) {
      if (d.sourceType === sourceType && d.sourceId === sourceId) return d;
    }
    return null;
  }

  async findById(documentId: string) {
    return this.docs.get(documentId) ?? null;
  }

  async listBySourcePrefixOrIds(sourceTypes: KnowledgeSourceType[], sourceIds: string[]) {
    return [...this.docs.values()].filter(
      (d) => sourceTypes.includes(d.sourceType) && sourceIds.includes(d.sourceId),
    );
  }

  async upsertDocumentAndChunks(params: UpsertKnowledgeDocumentParams): Promise<KnowledgeDocumentEntity> {
    const existing = await this.findBySource(params.sourceType, params.sourceId);
    const id = existing?.id ?? `doc-${this.seq++}`;
    const now = new Date();
    const doc: KnowledgeDocumentEntity = {
      id,
      sourceType: params.sourceType,
      sourceId: params.sourceId,
      authorId: params.authorId,
      title: params.title,
      subject: params.subject,
      language: params.language,
      visibility: params.visibility,
      trustTier: params.trustTier,
      classGroupIds: params.classGroupIds,
      contentHash: params.contentHash,
      indexStatus: params.indexStatus,
      embeddingModel: params.embeddingModel,
      embeddingDims: params.embeddingDims,
      chunkCount: params.chunks.length,
      errorMessage: params.errorMessage,
      indexedAt: params.indexedAt,
      metadata: params.metadata,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    };
    this.docs.set(id, doc);
    this.chunksByDoc.set(id, params.chunks);
    return doc;
  }

  async updateLifecycleBySource(params: {
    sourceType: KnowledgeSourceType;
    sourceId: string;
    visibility?: KnowledgeDocumentEntity['visibility'];
    trustTier?: KnowledgeDocumentEntity['trustTier'];
    classGroupIds?: string[];
  }) {
    const existing = await this.findBySource(params.sourceType, params.sourceId);
    if (!existing) return null;
    const updated: KnowledgeDocumentEntity = {
      ...existing,
      ...(params.visibility !== undefined ? { visibility: params.visibility } : {}),
      ...(params.trustTier !== undefined ? { trustTier: params.trustTier } : {}),
      ...(params.classGroupIds !== undefined ? { classGroupIds: params.classGroupIds } : {}),
      updatedAt: new Date(),
    };
    this.docs.set(updated.id, updated);
    return updated;
  }

  async updateLifecycleByCourseId(): Promise<void> {}
  async updateLifecycleByRecordingId(): Promise<void> {}

  async deleteById(documentId: string): Promise<void> {
    this.docs.delete(documentId);
    this.chunksByDoc.delete(documentId);
  }

  async deleteBySource(sourceType: KnowledgeSourceType, sourceId: string): Promise<void> {
    const existing = await this.findBySource(sourceType, sourceId);
    if (existing) await this.deleteById(existing.id);
  }

  async deleteByCourseId(): Promise<void> {}
  async deleteByRecordingId(): Promise<void> {}

  async listDocuments() {
    const items = [...this.docs.values()];
    return { items, total: items.length };
  }

  async listPendingOrFailedDocuments() {
    return [...this.docs.values()].filter((d) =>
      ['PENDING', 'INDEXING', 'PENDING_EMBEDDING', 'FAILED'].includes(d.indexStatus),
    );
  }

  async searchVectorCandidates() {
    return [];
  }

  async searchFtsCandidates(params: { query: string }) {
    const hits = [];
    for (const doc of this.docs.values()) {
      const chunks = this.chunksByDoc.get(doc.id) ?? [];
      for (const c of chunks) {
        if (c.content.toLowerCase().includes(params.query.toLowerCase().split(' ')[0] ?? '')) {
          hits.push({
            chunkId: `c-${doc.id}-${c.chunkIndex}`,
            documentId: doc.id,
            sourceType: doc.sourceType,
            sourceId: doc.sourceId,
            title: doc.title,
            subject: doc.subject,
            visibility: doc.visibility,
            trustTier: doc.trustTier,
            sectionTitle: c.sectionTitle,
            headingPath: c.headingPath,
            content: c.content,
            contextHeader: c.contextHeader,
            startSeconds: c.startSeconds,
            endSeconds: c.endSeconds,
            sourcePage: c.sourcePage,
            slideNumber: c.slideNumber,
            metadata: c.metadata,
            ftsRank: 0.9,
          });
        }
      }
    }
    return hits;
  }

  async logRetrieval(params: LogKnowledgeRetrievalParams): Promise<void> {
    this.logs.push(params);
  }

  async getAggregateCounts() {
    return {
      totalDocuments: this.docs.size,
      totalChunks: 0,
      embeddedChunks: 0,
      pendingEmbeddingDocuments: 0,
      failedDocuments: 0,
      bySourceType: {},
      byStatus: {},
      byTrustTier: {},
      byVisibility: {},
    };
  }

  async getRecentRetrievalStats() {
    return { totalLast24h: this.logs.length, hybridCount: 0, ftsOnlyCount: this.logs.length, vectorOnlyCount: 0 };
  }
}

describe('Unit: Knowledge Use Cases, SHA-256 Deduplication, Degraded Fallback & Recovery', () => {
  it('skips re-embedding unchanged SHA-256 content and syncs visibility metadata in place', async () => {
    const repo = new InMemoryKnowledgeRepository();
    let embedCalls = 0;
    const embedding: KnowledgeEmbeddingPort = {
      embedOne: async () => new Array(768).fill(0.01),
      embedBatch: async (texts) => {
        embedCalls += 1;
        return texts.map(() => new Array(768).fill(0.01));
      },
      checkHealth: async () => ({ available: true, model: 'embeddinggemma-2:270m', numGpu: 0, dimension: 768, latencyMs: 12, runtime: 'cpu' }),
    };

    const indexer = new IndexKnowledgeDocumentUseCase(repo, embedding);
    const input: KnowledgeIndexInput = {
      sourceType: 'COURSE',
      sourceId: 'course-1',
      authorId: 't1',
      title: 'Graphes',
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'DRAFT_AI',
      content: '# BFS\nParcours en largeur.',
    };

    const d1 = await indexer.execute(input);
    expect(d1?.indexStatus).toBe('INDEXED');
    expect(embedCalls).toBe(1);

    // Same content -> must NOT re-embed, even if visibility/classGroupIds promoted
    const d2 = await indexer.execute({
      ...input,
      visibility: 'CLASS_PUBLISHED',
      trustTier: 'VERIFIED',
      classGroupIds: ['class-1'],
    });
    expect(embedCalls).toBe(1);
    expect(d2?.visibility).toBe('CLASS_PUBLISHED');
    expect(d2?.trustTier).toBe('VERIFIED');
  });

  it('marks PENDING_EMBEDDING with null vectors when embedder fails and degrades search explicitly to FTS_ONLY', async () => {
    const repo = new InMemoryKnowledgeRepository();
    const downEmbed: KnowledgeEmbeddingPort = {
      embedOne: async () => {
        throw new Error('Ollama down');
      },
      embedBatch: async () => {
        throw new Error('Ollama down');
      },
      checkHealth: async () => ({ available: false, model: 'embeddinggemma-2:270m', numGpu: 0, dimension: 768, latencyMs: null, runtime: 'cpu' }),
    };

    const indexer = new IndexKnowledgeDocumentUseCase(repo, downEmbed);
    const doc = await indexer.execute({
      sourceType: 'COURSE',
      sourceId: 'course-offline',
      authorId: 't1',
      title: 'Réseaux',
      visibility: 'CLASS_PUBLISHED',
      trustTier: 'VERIFIED',
      classGroupIds: ['c1'],
      content: '# TCP\nProtocole orienté connexion fiable.',
    });

    expect(doc?.indexStatus).toBe('PENDING_EMBEDDING');
    expect(repo.chunksByDoc.get(doc!.id)?.[0]?.embedding).toBeNull();

    const search = new SearchKnowledgeUseCase(repo, downEmbed, {
      listEnrolledClassGroupIds: async () => ['c1'],
    });
    const res = await search.search({
      actor: { id: 's1', role: 'STUDENT' },
      query: 'Protocole TCP',
      k: 5,
    });
    expect(res.searchMode).toBe('FTS_ONLY');
    expect(res.degradedReason).toContain('Ollama down');
    expect(res.hits.length).toBe(1);
    expect(repo.logs[0]?.searchMode).toBe('FTS_ONLY');

    // Empty student enrollment must short-circuit without results
    const unscoped = new SearchKnowledgeUseCase(repo, downEmbed, {
      listEnrolledClassGroupIds: async () => [],
    });
    const blocked = await unscoped.search({ actor: { id: 's2', role: 'STUDENT' }, query: 'Protocole' });
    expect(blocked.hits).toEqual([]);
  });

  it('recovers PENDING_EMBEDDING docs on queue startup and enforces delete ownership', async () => {
    const repo = new InMemoryKnowledgeRepository();
    let online = false;
    const switchableEmbed: KnowledgeEmbeddingPort = {
      embedOne: async () => new Array(768).fill(0.02),
      embedBatch: async (texts) => {
        if (!online) throw new Error('offline');
        return texts.map(() => new Array(768).fill(0.02));
      },
      checkHealth: async () => ({ available: online, model: 'embeddinggemma-2:270m', numGpu: 0, dimension: 768, latencyMs: 10, runtime: 'cpu' }),
    };

    const sourceInput: KnowledgeIndexInput = {
      sourceType: 'COURSE',
      sourceId: 'course-rec',
      authorId: 't1',
      title: 'Récupération',
      visibility: 'PRIVATE_AUTHOR',
      trustTier: 'DRAFT_AI',
      content: '# Crash Recovery\nReprise automatique après redémarrage.',
    };

    const indexUseCase = new IndexKnowledgeDocumentUseCase(repo, switchableEmbed);
    const created = await indexUseCase.execute(sourceInput);
    expect(created?.indexStatus).toBe('PENDING_EMBEDDING');

    // Now runtime comes back online & backend recovers on startup
    online = true;
    const queue = new KnowledgeIndexQueueService(indexUseCase, repo, {
      loadAllCourses: async () => [sourceInput],
      loadAllCourseSections: async () => [],
      loadAllRecordings: async () => [],
      loadBySource: async (_st, id) => (id === 'course-rec' ? sourceInput : null),
    });

    const recoveredCount = await queue.recoverPendingDocuments();
    expect(recoveredCount).toBe(1);
    await queue.drain();

    const refreshed = await repo.findBySource('COURSE', 'course-rec');
    expect(refreshed?.indexStatus).toBe('INDEXED');

    const del = new DeleteKnowledgeDocumentUseCase(repo);
    await expect(
      del.execute({ id: 'other-teacher', role: 'TEACHER' }, refreshed!.id),
    ).rejects.toBeInstanceOf(ForbiddenError);

    const removed = await del.execute({ id: 't1', role: 'TEACHER' }, refreshed!.id);
    expect(removed.deleted).toBe(true);
  });

  it('bridges KnowledgeCourseRetrievalBridge cleanly with fallback to legacy adapter', async () => {
    const bridge = new KnowledgeCourseRetrievalBridge(
      {
        search: async () => ({
          query: 'q',
          searchMode: 'HYBRID',
          degradedReason: null,
          embeddingLatencyMs: 5,
          searchLatencyMs: 2,
          totalLatencyMs: 7,
          candidateCount: 0,
          hits: [],
        }),
      },
      {
        search: async () => [
          { passageId: 'leg-1', title: 'Legacy', content: 'Contenu hérité', score: 0.7 },
        ],
      },
    );

    const res = await bridge.search({ courseId: 'c1', authorId: 't1', query: 'hérité' });
    expect(res).toHaveLength(1);
    expect(res[0]?.passageId).toBe('leg-1');
  });
});
