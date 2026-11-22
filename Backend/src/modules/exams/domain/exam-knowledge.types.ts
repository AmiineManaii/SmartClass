import type {
  KnowledgeSearchMode,
  KnowledgeSourceType,
  KnowledgeTrustTier,
} from '../../knowledge/index.js';

export type ExamKnowledgeSearchMode = KnowledgeSearchMode | 'DIRECT_BALANCED';

export interface ExamKnowledgeSourceAttribution {
  documentId: string | null;
  sourceId: string;
  sourceType: KnowledgeSourceType;
  title: string;
  sectionTitle: string | null;
  trustTier: KnowledgeTrustTier;
  startSeconds: number | null;
  slideNumber: number | null;
  snippet: string;
  allocatedQuestions: number;
  retrievalOrigin: 'KNOWLEDGE_ENGINE' | 'COURSE_STRUCTURE';
}

export interface ExamSourceCoverageEntry {
  sourceId: string;
  documentId: string | null;
  title: string;
  sourceType: KnowledgeSourceType;
  chapters: string[];
  targetQuestions: number;
  charsIncluded: number;
  charsOriginal: number;
  trimmed: boolean;
}

export interface ExamCoverageReport {
  totalSources: number;
  coveredSources: number;
  totalChapters: number;
  coveredChapters: number;
  truncated: boolean;
  warnings: string[];
  distribution: ExamSourceCoverageEntry[];
}

export interface ExamKnowledgeBlueprint {
  promptContext: string;
  distributionPlan: string;
  knowledgeSources: ExamKnowledgeSourceAttribution[];
  coverage: ExamCoverageReport;
  searchMode: ExamKnowledgeSearchMode;
  degradedReason: string | null;
}
