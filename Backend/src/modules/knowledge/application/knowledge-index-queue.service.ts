import { logger } from '../../../shared/infrastructure/logger.js';
import type {
  KnowledgeIndexInput,
  KnowledgeSourceType,
  KnowledgeTrustTier,
  KnowledgeVisibility,
} from '../domain/knowledge-document.entity.js';
import type { KnowledgeIndexerPort } from '../domain/knowledge-indexer.port.js';
import type { KnowledgeRepositoryPort } from '../domain/knowledge-repository.port.js';
import type { KnowledgeSourceLoaderPort } from '../domain/knowledge-source-loader.port.js';
import type { IndexKnowledgeDocumentUseCase } from './index-knowledge-document.use-case.js';

/**
 * Bounded async single-worker background queue for Knowledge Engine indexing.
 * Coalesces repeated updates per `(sourceType, sourceId)`, supports crash
 * recovery on backend restart, and exposes `drain()` for graceful shutdown.
 */
export class KnowledgeIndexQueueService implements KnowledgeIndexerPort {
  private readonly pendingMap = new Map<string, KnowledgeIndexInput>();
  private readonly queueKeys: string[] = [];
  private running = false;
  private activePromise: Promise<void> | null = null;
  private drainWaiters: Array<() => void> = [];

  constructor(
    private readonly indexUseCase: IndexKnowledgeDocumentUseCase,
    private readonly repository: KnowledgeRepositoryPort,
    private readonly sourceLoader?: KnowledgeSourceLoaderPort,
  ) {}

  public async indexNow(input: KnowledgeIndexInput) {
    return this.indexUseCase.execute(input);
  }

  public enqueueIndex(input: KnowledgeIndexInput): void {
    const key = `${input.sourceType}:${input.sourceId}`;
    const alreadyQueued = this.pendingMap.has(key);
    this.pendingMap.set(key, input);
    if (!alreadyQueued) {
      this.queueKeys.push(key);
    }
    this.kick();
  }

  public async syncLifecycle(params: {
    sourceType: KnowledgeSourceType;
    sourceId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void> {
    await this.repository.updateLifecycleBySource(params);
  }

  public async syncCourseLifecycle(params: {
    courseId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void> {
    await this.repository.updateLifecycleByCourseId(params);
  }

  public async syncRecordingLifecycle(params: {
    recordingId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void> {
    await this.repository.updateLifecycleByRecordingId(params);
  }

  public async removeBySource(
    sourceType: KnowledgeSourceType,
    sourceId: string,
  ): Promise<void> {
    const key = `${sourceType}:${sourceId}`;
    this.pendingMap.delete(key);
    await this.repository.deleteBySource(sourceType, sourceId);
  }

  public async removeByCourseId(courseId: string): Promise<void> {
    this.pendingMap.delete(`COURSE:${courseId}`);
    await this.repository.deleteByCourseId(courseId);
  }

  public async removeByRecordingId(recordingId: string): Promise<void> {
    for (const st of [
      'LECTURE_TRANSCRIPT',
      'LECTURE_SLIDE',
      'LECTURE_PACKAGE',
      'RECORDING_SOURCE_DOC',
    ] as const) {
      this.pendingMap.delete(`${st}:${recordingId}`);
    }
    await this.repository.deleteByRecordingId(recordingId);
  }

  public async recoverPendingDocuments(): Promise<number> {
    if (!this.sourceLoader) return 0;
    const staleDocs = await this.repository.listPendingOrFailedDocuments(100);
    let queued = 0;

    for (const doc of staleDocs) {
      try {
        const freshInput = await this.sourceLoader.loadBySource(doc.sourceType, doc.sourceId);
        if (freshInput) {
          this.enqueueIndex({ ...freshInput, force: true });
          queued++;
        }
      } catch (err) {
        logger.warn(
          { documentId: doc.id, sourceType: doc.sourceType, sourceId: doc.sourceId, err },
          'Failed loading pending knowledge document during startup recovery',
        );
      }
    }

    if (queued > 0) {
      logger.info({ queued }, 'Knowledge Engine startup recovery re-queued pending/failed docs');
    }
    return queued;
  }

  public getStats(): { pending: number; running: boolean } {
    return {
      pending: this.queueKeys.length,
      running: this.running,
    };
  }

  public async drain(): Promise<void> {
    if (!this.running && this.queueKeys.length === 0) return;
    if (this.activePromise) {
      await this.activePromise;
    }
    if (this.running || this.queueKeys.length > 0) {
      await new Promise<void>((resolve) => {
        this.drainWaiters.push(resolve);
      });
    }
  }

  private kick(): void {
    if (this.running) return;
    this.running = true;
    this.activePromise = this.processLoop().finally(() => {
      this.running = false;
      this.activePromise = null;
      if (this.queueKeys.length > 0) {
        this.kick();
        return;
      }
      const waiters = this.drainWaiters;
      this.drainWaiters = [];
      for (const resolve of waiters) resolve();
    });
  }

  private async processLoop(): Promise<void> {
    while (this.queueKeys.length > 0) {
      const key = this.queueKeys.shift()!;
      const payload = this.pendingMap.get(key);
      this.pendingMap.delete(key);
      if (!payload) continue;

      try {
        await this.indexUseCase.execute(payload);
      } catch (err) {
        logger.error(
          { key, sourceType: payload.sourceType, sourceId: payload.sourceId, err },
          'Background knowledge indexing job failed',
        );
      }
    }
  }
}
