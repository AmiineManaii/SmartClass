import type { Role } from '../../auth/index.js';

export type KnowledgeSourceType =
  | 'COURSE'
  | 'COURSE_SECTION'
  | 'LECTURE_TRANSCRIPT'
  | 'LECTURE_SLIDE'
  | 'LECTURE_PACKAGE'
  | 'RECORDING_SOURCE_DOC'
  | 'UPLOADED_DOCUMENT';

export type KnowledgeVisibility = 'PRIVATE_AUTHOR' | 'CLASS_PUBLISHED' | 'INSTITUTION_SHARED';

export type KnowledgeTrustTier = 'DRAFT_AI' | 'VERIFIED';

export type KnowledgeIndexStatus =
  | 'PENDING'
  | 'INDEXING'
  | 'INDEXED'
  | 'PENDING_EMBEDDING'
  | 'FAILED';

export type KnowledgeSearchMode = 'HYBRID' | 'FTS_ONLY' | 'VECTOR_ONLY';

export interface KnowledgeActor {
  id: string;
  role: Role;
}

export interface KnowledgeDocumentEntity {
  id: string;
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
  chunkCount: number;
  errorMessage: string | null;
  indexedAt: Date | null;
  metadata: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

export interface KnowledgeChunkEntity {
  id: string;
  documentId: string;
  chunkIndex: number;
  sectionTitle: string | null;
  headingPath: string | null;
  content: string;
  contextHeader: string;
  tokenEstimate: number;
  startSeconds: number | null;
  endSeconds: number | null;
  sourcePage: number | null;
  slideNumber: number | null;
  contentHash: string;
  hasEmbedding: boolean;
  metadata: Record<string, unknown>;
  createdAt: Date;
  updatedAt: Date;
}

export interface KnowledgeChunkDraft {
  chunkIndex: number;
  sectionTitle: string | null;
  headingPath: string | null;
  content: string;
  contextHeader: string;
  tokenEstimate: number;
  startSeconds: number | null;
  endSeconds: number | null;
  sourcePage: number | null;
  slideNumber: number | null;
  contentHash: string;
  metadata: Record<string, unknown>;
}

export interface KnowledgeTranscriptSegmentInput {
  startSeconds: number;
  endSeconds: number;
  text: string;
  speaker?: string | null;
}

export interface KnowledgeChapterInput {
  orderIndex: number;
  title: string;
  summary: string;
  startSeconds: number;
  endSeconds: number;
  keyConcepts?: string[];
  sourcePage?: number | null;
}

export interface KnowledgeSlideInput {
  slideNumber: number;
  timestampSeconds: number;
  ocrText: string;
  visualSummary: string;
  sourcePage?: number | null;
}

export interface KnowledgePackageInput {
  generalSummary?: string | null;
  structuredNotes?: string | null;
  keyConcepts?: Array<{
    name: string;
    explanation: string;
    timestampSeconds?: number;
    sourcePage?: number;
  }>;
  definitions?: Array<{
    term: string;
    definition: string;
    chapterTitle?: string;
    timestampSeconds?: number;
  }>;
  formulasAndRules?: string[];
  examples?: Array<{
    title: string;
    description: string;
    solutionOrWalkthrough: string;
    timestampSeconds?: number;
  }>;
  importantMoments?: Array<{
    label: string;
    timestampSeconds: number;
    reason: string;
    chapterTitle?: string;
  }>;
}

export interface KnowledgeIndexInput {
  sourceType: KnowledgeSourceType;
  sourceId: string;
  authorId: string;
  title: string;
  subject?: string | null;
  language?: string;
  visibility: KnowledgeVisibility;
  trustTier: KnowledgeTrustTier;
  classGroupIds?: string[];
  content?: string | null;
  transcriptSegments?: KnowledgeTranscriptSegmentInput[];
  chapters?: KnowledgeChapterInput[];
  slides?: KnowledgeSlideInput[];
  lessonPackage?: KnowledgePackageInput | null;
  metadata?: Record<string, unknown>;
  force?: boolean;
}

export interface KnowledgeSearchFilters {
  sourceTypes?: KnowledgeSourceType[];
  sourceIds?: string[];
  documentIds?: string[];
  subject?: string;
  classGroupIds?: string[];
  trustTiers?: KnowledgeTrustTier[];
}

export interface KnowledgeSearchHit {
  chunkId: string;
  documentId: string;
  sourceType: KnowledgeSourceType;
  sourceId: string;
  title: string;
  subject: string | null;
  visibility: KnowledgeVisibility;
  trustTier: KnowledgeTrustTier;
  sectionTitle: string | null;
  headingPath: string | null;
  content: string;
  contextHeader: string;
  startSeconds: number | null;
  endSeconds: number | null;
  sourcePage: number | null;
  slideNumber: number | null;
  score: number;
  vectorScore: number | null;
  ftsScore: number | null;
  metadata: Record<string, unknown>;
}

export interface KnowledgeSearchResult {
  query: string;
  searchMode: KnowledgeSearchMode;
  degradedReason: string | null;
  embeddingLatencyMs: number | null;
  searchLatencyMs: number;
  totalLatencyMs: number;
  candidateCount: number;
  hits: KnowledgeSearchHit[];
}

export interface KnowledgeStatusReport {
  embeddingHealth: {
    available: boolean;
    model: string;
    numGpu: number;
    dimension: number;
    latencyMs: number | null;
    runtime: 'cpu' | 'gpu';
  };
  queue: {
    pending: number;
    running: boolean;
  };
  counts: {
    totalDocuments: number;
    totalChunks: number;
    embeddedChunks: number;
    pendingEmbeddingDocuments: number;
    failedDocuments: number;
    bySourceType: Record<string, number>;
    byStatus: Record<string, number>;
    byTrustTier: Record<string, number>;
    byVisibility: Record<string, number>;
  };
  recentRetrievals: {
    totalLast24h: number;
    hybridCount: number;
    ftsOnlyCount: number;
    vectorOnlyCount: number;
  };
}
