import type {
  KnowledgeChunkDraft,
  KnowledgeDocumentEntity,
  KnowledgeIndexStatus,
  KnowledgeSearchFilters,
  KnowledgeSearchMode,
  KnowledgeSourceType,
  KnowledgeStatusReport,
  KnowledgeTrustTier,
  KnowledgeVisibility,
} from './knowledge-document.entity.js';
import type { KnowledgeRetrievalScope } from './knowledge-policy.js';
import type { FtsCandidate, VectorCandidate } from './hybrid-ranker.js';
import type { Role } from '../../auth/index.js';

export interface UpsertKnowledgeDocumentParams {
  sourceType: KnowledgeSourceType;
  sourceId: string;
  authorId: string;
  title: string;
  subject: string | null;
  language: string;
  visibility: KnowledgeVisibility;
  trustTier: KnowledgeTrustTier;
  classGroupIds: string[];
  contentHash: string;
  indexStatus: KnowledgeIndexStatus;
  embeddingModel: string | null;
  embeddingDims: number;
  errorMessage: string | null;
  indexedAt: Date | null;
  metadata: Record<string, unknown>;
  chunks: Array<KnowledgeChunkDraft & { embedding: number[] | null }>;
}

export interface ListKnowledgeDocumentsParams {
  scope: KnowledgeRetrievalScope;
  sourceTypes?: KnowledgeSourceType[];
  indexStatuses?: KnowledgeIndexStatus[];
  subject?: string;
  page: number;
  limit: number;
}

export interface LogKnowledgeRetrievalParams {
  userId: string;
  userRole: Role;
  query: string;
  queryHash: string;
  searchMode: KnowledgeSearchMode;
  degradedReason: string | null;
  filters: Record<string, unknown>;
  candidateCount: number;
  returnedCount: number;
  topScore: number | null;
  embeddingLatencyMs: number | null;
  searchLatencyMs: number;
  totalLatencyMs: number;
}

export interface KnowledgeRepositoryPort {
  ensureSchemaArtifacts(): Promise<void>;
  findBySource(sourceType: KnowledgeSourceType, sourceId: string): Promise<KnowledgeDocumentEntity | null>;
  findById(documentId: string): Promise<KnowledgeDocumentEntity | null>;
  listBySourcePrefixOrIds(
    sourceTypes: KnowledgeSourceType[],
    sourceIds: string[],
  ): Promise<KnowledgeDocumentEntity[]>;
  upsertDocumentAndChunks(params: UpsertKnowledgeDocumentParams): Promise<KnowledgeDocumentEntity>;
  updateLifecycleBySource(params: {
    sourceType: KnowledgeSourceType;
    sourceId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<KnowledgeDocumentEntity | null>;
  updateLifecycleByCourseId(params: {
    courseId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void>;
  updateLifecycleByRecordingId(params: {
    recordingId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void>;
  deleteById(documentId: string): Promise<void>;
  deleteBySource(sourceType: KnowledgeSourceType, sourceId: string): Promise<void>;
  deleteByCourseId(courseId: string): Promise<void>;
  deleteByRecordingId(recordingId: string): Promise<void>;
  listDocuments(params: ListKnowledgeDocumentsParams): Promise<{
    items: KnowledgeDocumentEntity[];
    total: number;
  }>;
  listPendingOrFailedDocuments(limit?: number): Promise<KnowledgeDocumentEntity[]>;
  searchVectorCandidates(params: {
    scope: KnowledgeRetrievalScope;
    queryVector: number[];
    filters?: KnowledgeSearchFilters;
    limit: number;
  }): Promise<VectorCandidate[]>;
  searchFtsCandidates(params: {
    scope: KnowledgeRetrievalScope;
    query: string;
    filters?: KnowledgeSearchFilters;
    limit: number;
  }): Promise<FtsCandidate[]>;
  logRetrieval(params: LogKnowledgeRetrievalParams): Promise<void>;
  getAggregateCounts(): Promise<KnowledgeStatusReport['counts']>;
  getRecentRetrievalStats(): Promise<KnowledgeStatusReport['recentRetrievals']>;
}
