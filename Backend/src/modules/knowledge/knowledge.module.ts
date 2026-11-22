import type { RequestHandler, Router } from 'express';
import { logger } from '../../shared/infrastructure/logger.js';
import {
  createAuthenticateMiddleware,
  createRequireApprovedTeacherMiddleware,
  type Role,
  type TokenServicePort,
} from '../auth/index.js';
import type { GroupRepositoryPort } from '../groups/domain/group-repository.port.js';
import { IndexKnowledgeDocumentUseCase } from './application/index-knowledge-document.use-case.js';
import { KnowledgeIndexQueueService } from './application/knowledge-index-queue.service.js';
import {
  DeleteKnowledgeDocumentUseCase,
  GetKnowledgeDocumentUseCase,
  GetKnowledgeStatusUseCase,
  ListKnowledgeDocumentsUseCase,
  ReindexKnowledgeUseCase,
} from './application/knowledge-management.use-cases.js';
import { SearchKnowledgeUseCase } from './application/search-knowledge.use-case.js';
import type { ClassMembershipPort } from './domain/class-membership.port.js';
import type { KnowledgeEmbeddingPort } from './domain/knowledge-embedding.port.js';
import type { KnowledgeIndexerPort } from './domain/knowledge-indexer.port.js';
import type { KnowledgeRepositoryPort } from './domain/knowledge-repository.port.js';
import type { KnowledgeRetrievalPort } from './domain/knowledge-retrieval.port.js';
import type { KnowledgeSourceLoaderPort } from './domain/knowledge-source-loader.port.js';
import { OllamaCpuEmbeddingAdapter } from './infrastructure/ollama-cpu-embedding.adapter.js';
import { PrismaClassMembershipAdapter } from './infrastructure/prisma-class-membership.adapter.js';
import { PrismaKnowledgeRepositoryAdapter } from './infrastructure/prisma-knowledge-repository.adapter.js';
import { PrismaKnowledgeSourceLoaderAdapter } from './infrastructure/prisma-knowledge-source-loader.adapter.js';
import { KnowledgeController } from './presentation/knowledge.controller.js';
import { createKnowledgeRouter } from './presentation/knowledge.routes.js';

export interface KnowledgeModuleOptions {
  repository?: KnowledgeRepositoryPort;
  embedding?: KnowledgeEmbeddingPort;
  classMembership?: ClassMembershipPort;
  groupRepository?: GroupRepositoryPort;
  sourceLoader?: KnowledgeSourceLoaderPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireTeacherMiddleware?: RequestHandler;
}

export interface KnowledgeModule {
  router: Router;
  controller: KnowledgeController;
  repository: KnowledgeRepositoryPort;
  embedding: KnowledgeEmbeddingPort;
  indexer: KnowledgeIndexerPort;
  retrieval: KnowledgeRetrievalPort;
  initialize(): Promise<void>;
  shutdown(): Promise<void>;
}

export const createKnowledgeModule = (options: KnowledgeModuleOptions = {}): KnowledgeModule => {
  const repository = options.repository ?? new PrismaKnowledgeRepositoryAdapter();
  const embedding = options.embedding ?? new OllamaCpuEmbeddingAdapter();
  const classMembership =
    options.classMembership ?? new PrismaClassMembershipAdapter(options.groupRepository);
  const sourceLoader = options.sourceLoader ?? new PrismaKnowledgeSourceLoaderAdapter();

  const indexUseCase = new IndexKnowledgeDocumentUseCase(repository, embedding);
  const indexQueue = new KnowledgeIndexQueueService(indexUseCase, repository, sourceLoader);
  const searchUseCase = new SearchKnowledgeUseCase(repository, embedding, classMembership);
  const listDocumentsUseCase = new ListKnowledgeDocumentsUseCase(repository, classMembership);
  const getDocumentUseCase = new GetKnowledgeDocumentUseCase(repository, classMembership);
  const deleteDocumentUseCase = new DeleteKnowledgeDocumentUseCase(repository);
  const reindexUseCase = new ReindexKnowledgeUseCase(indexQueue, sourceLoader, repository);
  const statusUseCase = new GetKnowledgeStatusUseCase(repository, embedding, indexQueue);

  const controller = new KnowledgeController(
    searchUseCase,
    listDocumentsUseCase,
    getDocumentUseCase,
    deleteDocumentUseCase,
    reindexUseCase,
    statusUseCase,
  );

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    if (!options.tokenService) {
      throw new Error('KnowledgeModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(options.tokenService);
  }

  const requireTeacherMiddleware =
    options.requireTeacherMiddleware ??
    createRequireApprovedTeacherMiddleware(['TEACHER', 'ADMIN'] as Role[]);

  const router = createKnowledgeRouter({
    controller,
    authenticateMiddleware,
    requireTeacherMiddleware,
  });

  return {
    router,
    controller,
    repository,
    embedding,
    indexer: indexQueue,
    retrieval: searchUseCase,
    initialize: async () => {
      try {
        await repository.ensureSchemaArtifacts();
        await indexQueue.recoverPendingDocuments();
      } catch (err) {
        logger.warn({ err }, 'Knowledge Engine initialization skipped/degraded during startup');
      }
    },
    shutdown: async () => {
      await indexQueue.drain();
    },
  };
};
