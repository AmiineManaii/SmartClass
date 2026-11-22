import type {
  KnowledgeSearchMode,
  KnowledgeSourceType,
  KnowledgeTrustTier,
} from '../../knowledge/index.js';

export type KnowledgeGroundingSearchMode = KnowledgeSearchMode | 'DISABLED';

export interface KnowledgeGroundingOptions {
  enabled?: boolean;
  sourceTypes?: KnowledgeSourceType[];
  documentIds?: string[];
  includeDrafts?: boolean;
  maxChunks?: number;
}

export interface KnowledgeSourceAttribution {
  documentId: string;
  chunkId: string;
  sourceType: KnowledgeSourceType;
  sourceId: string;
  title: string;
  sectionTitle: string | null;
  trustTier: KnowledgeTrustTier;
  score: number;
  vectorScore: number | null;
  ftsScore: number | null;
  startSeconds: number | null;
  sourcePage: number | null;
  slideNumber: number | null;
  snippet: string;
}

export interface KnowledgeGroundingOutcome {
  promptContext: string;
  sources: KnowledgeSourceAttribution[];
  searchMode: KnowledgeGroundingSearchMode;
  degradedReason: string | null;
}
