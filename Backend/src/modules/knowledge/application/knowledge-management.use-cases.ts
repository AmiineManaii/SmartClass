import { ForbiddenError, KnowledgeDocumentNotFoundError } from '../../../shared/errors/app-error.js';
import {
  buildOffsetPaginationMeta,
  type OffsetPaginationResult,
} from '../../../shared/http/pagination/index.js';
import type { ClassMembershipPort } from '../domain/class-membership.port.js';
import type {
  KnowledgeActor,
  KnowledgeDocumentEntity,
  KnowledgeIndexStatus,
  KnowledgeSourceType,
  KnowledgeStatusReport,
  KnowledgeTrustTier,
  KnowledgeVisibility,
} from '../domain/knowledge-document.entity.js';
import type { KnowledgeEmbeddingPort } from '../domain/knowledge-embedding.port.js';
import type { KnowledgeIndexerPort } from '../domain/knowledge-indexer.port.js';
import {
  canManageDocument,
  canReadDocument,
  resolveRetrievalScope,
} from '../domain/knowledge-policy.js';
import type { KnowledgeRepositoryPort } from '../domain/knowledge-repository.port.js';
import type { KnowledgeSourceLoaderPort } from '../domain/knowledge-source-loader.port.js';
import type { KnowledgeIndexQueueService } from './knowledge-index-queue.service.js';

export class ListKnowledgeDocumentsUseCase {
  constructor(
    private readonly repository: KnowledgeRepositoryPort,
    private readonly classMembership: ClassMembershipPort,
  ) {}

  public async execute(params: {
    actor: KnowledgeActor;
    sourceTypes?: KnowledgeSourceType[];
    indexStatuses?: KnowledgeIndexStatus[];
    subject?: string;
    page: number;
    limit: number;
  }): Promise<OffsetPaginationResult<KnowledgeDocumentEntity>> {
    const enrolled =
      params.actor.role === 'STUDENT'
        ? await this.classMembership.listEnrolledClassGroupIds(params.actor.id)
        : [];
    const scope = resolveRetrievalScope(params.actor, enrolled);
    const { items, total } = await this.repository.listDocuments({
      scope,
      sourceTypes: params.sourceTypes,
      indexStatuses: params.indexStatuses,
      subject: params.subject,
      page: params.page,
      limit: params.limit,
    });

    return {
      data: items,
      meta: buildOffsetPaginationMeta({
        page: params.page,
        limit: params.limit,
        total,
      }),
    };
  }
}

export class GetKnowledgeDocumentUseCase {
  constructor(
    private readonly repository: KnowledgeRepositoryPort,
    private readonly classMembership: ClassMembershipPort,
  ) {}

  public async execute(actor: KnowledgeActor, documentId: string): Promise<KnowledgeDocumentEntity> {
    const doc = await this.repository.findById(documentId);
    if (!doc) {
      throw new KnowledgeDocumentNotFoundError();
    }
    const enrolled =
      actor.role === 'STUDENT' ? await this.classMembership.listEnrolledClassGroupIds(actor.id) : [];
    if (!canReadDocument(actor, doc, enrolled)) {
      throw new ForbiddenError('You are not authorized to access this knowledge document');
    }
    return doc;
  }
}

export class DeleteKnowledgeDocumentUseCase {
  constructor(private readonly repository: KnowledgeRepositoryPort) {}

  public async execute(
    actor: KnowledgeActor,
    documentId: string,
  ): Promise<{ id: string; deleted: boolean }> {
    const doc = await this.repository.findById(documentId);
    if (!doc) {
      throw new KnowledgeDocumentNotFoundError();
    }
    if (!canManageDocument(actor, doc)) {
      throw new ForbiddenError('Only the author or an administrator can delete this document');
    }
    await this.repository.deleteById(documentId);
    return { id: documentId, deleted: true };
  }
}

export class SyncKnowledgeVisibilityUseCase {
  constructor(private readonly indexer: KnowledgeIndexerPort) {}

  public async syncSource(params: {
    sourceType: KnowledgeSourceType;
    sourceId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void> {
    await this.indexer.syncLifecycle(params);
  }
}

export class ReindexKnowledgeUseCase {
  constructor(
    private readonly indexer: KnowledgeIndexerPort,
    private readonly sourceLoader: KnowledgeSourceLoaderPort,
    private readonly repository: KnowledgeRepositoryPort,
  ) {}

  public async execute(params: {
    actor: KnowledgeActor;
    sourceTypes?: KnowledgeSourceType[];
    documentId?: string;
    force?: boolean;
  }): Promise<{
    processedCount: number;
    indexedCount: number;
    pendingEmbeddingCount: number;
    failedCount: number;
  }> {
    if (params.actor.role !== 'TEACHER' && params.actor.role !== 'ADMIN') {
      throw new ForbiddenError('Only approved teachers or administrators can reindex knowledge');
    }

    if (params.documentId) {
      const existing = await this.repository.findById(params.documentId);
      if (!existing) throw new KnowledgeDocumentNotFoundError();
      if (!canManageDocument(params.actor, existing)) {
        throw new ForbiddenError('You can only reindex your own knowledge documents');
      }
      const input = await this.sourceLoader.loadBySource(existing.sourceType, existing.sourceId);
      if (!input) throw new KnowledgeDocumentNotFoundError('Backing source no longer exists');
      const doc = await this.indexer.indexNow({ ...input, force: params.force ?? true });
      return {
        processedCount: 1,
        indexedCount: doc?.indexStatus === 'INDEXED' ? 1 : 0,
        pendingEmbeddingCount: doc?.indexStatus === 'PENDING_EMBEDDING' ? 1 : 0,
        failedCount: doc?.indexStatus === 'FAILED' ? 1 : 0,
      };
    }

    const authorFilter = params.actor.role === 'ADMIN' ? undefined : params.actor.id;
    const requestedTypes = new Set(params.sourceTypes ?? []);
    const wantsAll = requestedTypes.size === 0;

    const batches = await Promise.all([
      wantsAll || requestedTypes.has('COURSE')
        ? this.sourceLoader.loadAllCourses(authorFilter)
        : [],
      wantsAll || requestedTypes.has('COURSE_SECTION')
        ? this.sourceLoader.loadAllCourseSections(authorFilter)
        : [],
      wantsAll ||
      requestedTypes.has('LECTURE_TRANSCRIPT') ||
      requestedTypes.has('LECTURE_SLIDE') ||
      requestedTypes.has('LECTURE_PACKAGE') ||
      requestedTypes.has('RECORDING_SOURCE_DOC')
        ? this.sourceLoader.loadAllRecordings(authorFilter)
        : [],
    ]);

    const inputs = batches
      .flat()
      .filter((item) => wantsAll || requestedTypes.has(item.sourceType));

    let indexedCount = 0;
    let pendingEmbeddingCount = 0;
    let failedCount = 0;

    for (const item of inputs) {
      try {
        const res = await this.indexer.indexNow({ ...item, force: params.force ?? false });
        if (res?.indexStatus === 'INDEXED') indexedCount++;
        else if (res?.indexStatus === 'PENDING_EMBEDDING') pendingEmbeddingCount++;
        else failedCount++;
      } catch {
        failedCount++;
      }
    }

    return {
      processedCount: inputs.length,
      indexedCount,
      pendingEmbeddingCount,
      failedCount,
    };
  }
}

export class GetKnowledgeStatusUseCase {
  constructor(
    private readonly repository: KnowledgeRepositoryPort,
    private readonly embedding: KnowledgeEmbeddingPort,
    private readonly queue: Pick<KnowledgeIndexQueueService, 'getStats'>,
  ) {}

  public async execute(): Promise<KnowledgeStatusReport> {
    const [embeddingHealth, counts, recentRetrievals] = await Promise.all([
      this.embedding.checkHealth(),
      this.repository.getAggregateCounts(),
      this.repository.getRecentRetrievalStats(),
    ]);

    return {
      embeddingHealth,
      queue: this.queue.getStats(),
      counts,
      recentRetrievals,
    };
  }
}
