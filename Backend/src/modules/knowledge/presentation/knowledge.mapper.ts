import type {
  KnowledgeDocumentEntity,
  KnowledgeSearchHit,
  KnowledgeSearchResult,
  KnowledgeStatusReport,
} from '../domain/knowledge-document.entity.js';

export interface KnowledgeDocumentDto {
  id: string;
  sourceType: string;
  sourceId: string;
  authorId: string;
  title: string;
  subject: string | null;
  language: string;
  visibility: string;
  trustTier: string;
  classGroupIds: string[];
  contentHash: string;
  indexStatus: string;
  embeddingModel: string | null;
  embeddingDims: number;
  chunkCount: number;
  errorMessage: string | null;
  indexedAt: string | null;
  metadata: Record<string, unknown>;
  createdAt: string;
  updatedAt: string;
}

export const toKnowledgeDocumentDto = (doc: KnowledgeDocumentEntity): KnowledgeDocumentDto => ({
  id: doc.id,
  sourceType: doc.sourceType,
  sourceId: doc.sourceId,
  authorId: doc.authorId,
  title: doc.title,
  subject: doc.subject,
  language: doc.language,
  visibility: doc.visibility,
  trustTier: doc.trustTier,
  classGroupIds: doc.classGroupIds,
  contentHash: doc.contentHash,
  indexStatus: doc.indexStatus,
  embeddingModel: doc.embeddingModel,
  embeddingDims: doc.embeddingDims,
  chunkCount: doc.chunkCount,
  errorMessage: doc.errorMessage,
  indexedAt: doc.indexedAt ? doc.indexedAt.toISOString() : null,
  metadata: doc.metadata,
  createdAt: doc.createdAt.toISOString(),
  updatedAt: doc.updatedAt.toISOString(),
});

export const toKnowledgeSearchResponseDto = (
  result: KnowledgeSearchResult,
): {
  query: string;
  searchMode: string;
  degradedReason: string | null;
  embeddingLatencyMs: number | null;
  searchLatencyMs: number;
  totalLatencyMs: number;
  candidateCount: number;
  hits: KnowledgeSearchHit[];
} => ({
  query: result.query,
  searchMode: result.searchMode,
  degradedReason: result.degradedReason,
  embeddingLatencyMs: result.embeddingLatencyMs,
  searchLatencyMs: result.searchLatencyMs,
  totalLatencyMs: result.totalLatencyMs,
  candidateCount: result.candidateCount,
  hits: result.hits,
});

export const toKnowledgeStatusDto = (status: KnowledgeStatusReport): KnowledgeStatusReport => status;
