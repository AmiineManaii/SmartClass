import type {
  KnowledgeDocumentEntity,
  KnowledgeIndexInput,
  KnowledgeSourceType,
  KnowledgeTrustTier,
  KnowledgeVisibility,
} from './knowledge-document.entity.js';

export interface KnowledgeIndexerPort {
  indexNow(input: KnowledgeIndexInput): Promise<KnowledgeDocumentEntity | null>;
  enqueueIndex(input: KnowledgeIndexInput): void;
  syncLifecycle(params: {
    sourceType: KnowledgeSourceType;
    sourceId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void>;
  syncCourseLifecycle(params: {
    courseId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void>;
  syncRecordingLifecycle(params: {
    recordingId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void>;
  removeBySource(sourceType: KnowledgeSourceType, sourceId: string): Promise<void>;
  removeByCourseId(courseId: string): Promise<void>;
  removeByRecordingId(recordingId: string): Promise<void>;
}
