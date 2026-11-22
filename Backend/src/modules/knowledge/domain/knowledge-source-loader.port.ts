import type { KnowledgeIndexInput } from './knowledge-document.entity.js';

export interface KnowledgeSourceLoaderPort {
  loadAllCourses(authorId?: string): Promise<KnowledgeIndexInput[]>;
  loadAllCourseSections(authorId?: string): Promise<KnowledgeIndexInput[]>;
  loadAllRecordings(authorId?: string): Promise<KnowledgeIndexInput[]>;
  loadBySource(sourceType: KnowledgeIndexInput['sourceType'], sourceId: string): Promise<KnowledgeIndexInput | null>;
}
