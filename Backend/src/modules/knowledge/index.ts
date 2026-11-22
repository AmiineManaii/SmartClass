export { createKnowledgeModule, type KnowledgeModule, type KnowledgeModuleOptions } from './knowledge.module.js';
export { KNOWLEDGE_SOURCE_TYPES } from './presentation/knowledge.validation.js';
export type {
  KnowledgeSourceType,
  KnowledgeVisibility,
  KnowledgeTrustTier,
  KnowledgeIndexStatus,
  KnowledgeSearchMode,
  KnowledgeActor,
  KnowledgeDocumentEntity,
  KnowledgeChunkEntity,
  KnowledgeChunkDraft,
  KnowledgeIndexInput,
  KnowledgeSearchFilters,
  KnowledgeSearchHit,
  KnowledgeSearchResult,
  KnowledgeStatusReport,
} from './domain/knowledge-document.entity.js';
export type { KnowledgeEmbeddingPort, KnowledgeEmbeddingHealth } from './domain/knowledge-embedding.port.js';
export type { KnowledgeIndexerPort } from './domain/knowledge-indexer.port.js';
export type { KnowledgeRetrievalPort, KnowledgeSearchRequest } from './domain/knowledge-retrieval.port.js';
export type { KnowledgeRepositoryPort } from './domain/knowledge-repository.port.js';
export type { ClassMembershipPort } from './domain/class-membership.port.js';
export type { KnowledgeSourceLoaderPort } from './domain/knowledge-source-loader.port.js';
export { KnowledgeSectionMemoryBridge } from './infrastructure/knowledge-section-memory.bridge.js';
export { KnowledgeCourseRetrievalBridge } from './infrastructure/knowledge-course-retrieval.bridge.js';
export { resolveRetrievalScope, canReadDocument, canManageDocument } from './domain/knowledge-policy.js';
export { chunkKnowledgeInput, computeSha256, estimateTokens } from './domain/structure-chunker.js';
export { fuseAndDiversifyRrfMmr } from './domain/hybrid-ranker.js';
