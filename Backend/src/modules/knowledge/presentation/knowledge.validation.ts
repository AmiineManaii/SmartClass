import { z } from 'zod';
import { offsetPaginationQuerySchema } from '../../../shared/http/pagination/index.js';

export const KNOWLEDGE_SOURCE_TYPES = [
  'COURSE',
  'COURSE_SECTION',
  'LECTURE_TRANSCRIPT',
  'LECTURE_SLIDE',
  'LECTURE_PACKAGE',
  'RECORDING_SOURCE_DOC',
  'UPLOADED_DOCUMENT',
] as const;

export const KNOWLEDGE_INDEX_STATUSES = [
  'PENDING',
  'INDEXING',
  'INDEXED',
  'PENDING_EMBEDDING',
  'FAILED',
] as const;

export const KNOWLEDGE_TRUST_TIERS = ['DRAFT_AI', 'VERIFIED'] as const;

export const KNOWLEDGE_SEARCH_MODES = ['HYBRID', 'FTS_ONLY', 'VECTOR_ONLY'] as const;

export const searchKnowledgeSchema = z
  .object({
    query: z.string().trim().min(1).max(1500),
    k: z.coerce.number().int().min(1).max(20).optional().default(6),
    preferredMode: z.enum(KNOWLEDGE_SEARCH_MODES).optional(),
    filters: z
      .object({
        sourceTypes: z.array(z.enum(KNOWLEDGE_SOURCE_TYPES)).min(1).max(7).optional(),
        sourceIds: z.array(z.string().trim().min(1)).min(1).max(25).optional(),
        documentIds: z.array(z.string().uuid()).min(1).max(25).optional(),
        subject: z.string().trim().min(1).max(160).optional(),
        classGroupIds: z.array(z.string().uuid()).min(1).max(25).optional(),
        trustTiers: z.array(z.enum(KNOWLEDGE_TRUST_TIERS)).min(1).max(2).optional(),
      })
      .strict()
      .optional(),
  })
  .strict();

export const listKnowledgeDocumentsQuerySchema = offsetPaginationQuerySchema
  .extend({
    sourceType: z.enum(KNOWLEDGE_SOURCE_TYPES).optional(),
    indexStatus: z.enum(KNOWLEDGE_INDEX_STATUSES).optional(),
    subject: z.string().trim().min(1).max(160).optional(),
  })
  .strict();

export const documentIdParamsSchema = z
  .object({
    id: z.string().uuid(),
  })
  .strict();

export const reindexKnowledgeSchema = z
  .object({
    sourceTypes: z.array(z.enum(KNOWLEDGE_SOURCE_TYPES)).min(1).max(7).optional(),
    documentId: z.string().uuid().optional(),
    force: z.boolean().optional().default(false),
  })
  .strict();
