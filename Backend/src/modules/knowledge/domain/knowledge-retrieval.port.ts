import type {
  KnowledgeActor,
  KnowledgeSearchFilters,
  KnowledgeSearchMode,
  KnowledgeSearchResult,
} from './knowledge-document.entity.js';

export interface KnowledgeSearchRequest {
  actor: KnowledgeActor;
  query: string;
  k?: number;
  preferredMode?: KnowledgeSearchMode;
  filters?: KnowledgeSearchFilters;
}

export interface KnowledgeRetrievalPort {
  search(request: KnowledgeSearchRequest): Promise<KnowledgeSearchResult>;
}
