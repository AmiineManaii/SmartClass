import { randomUUID } from 'node:crypto';
import type { Prisma, PrismaClient } from '@prisma/client';
import { getPgPool, getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type { FtsCandidate, VectorCandidate } from '../domain/hybrid-ranker.js';
import type {
  KnowledgeDocumentEntity,
  KnowledgeIndexStatus,
  KnowledgeSearchFilters,
  KnowledgeSearchMode,
  KnowledgeSourceType,
  KnowledgeStatusReport,
  KnowledgeTrustTier,
  KnowledgeVisibility,
} from '../domain/knowledge-document.entity.js';
import type { KnowledgeRetrievalScope } from '../domain/knowledge-policy.js';
import type {
  KnowledgeRepositoryPort,
  ListKnowledgeDocumentsParams,
  LogKnowledgeRetrievalParams,
  UpsertKnowledgeDocumentParams,
} from '../domain/knowledge-repository.port.js';

const toVectorLiteral = (vector: number[]): string => `[${vector.join(',')}]`;

const parseVectorText = (raw: string | null | undefined): number[] | null => {
  if (!raw || typeof raw !== 'string') return null;
  const trimmed = raw.trim();
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) return null;
  const parts = trimmed.slice(1, -1).split(',');
  if (parts.length === 0) return null;
  return parts.map((p) => Number.parseFloat(p) || 0);
};

const toRecord = (value: unknown): Record<string, unknown> =>
  typeof value === 'object' && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : {};

const mapPrismaDoc = (row: {
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
  metadata: unknown;
  createdAt: Date;
  updatedAt: Date;
}): KnowledgeDocumentEntity => ({
  id: row.id,
  sourceType: row.sourceType,
  sourceId: row.sourceId,
  authorId: row.authorId,
  title: row.title,
  subject: row.subject,
  language: row.language,
  visibility: row.visibility,
  trustTier: row.trustTier,
  classGroupIds: row.classGroupIds,
  contentHash: row.contentHash,
  indexStatus: row.indexStatus,
  embeddingModel: row.embeddingModel,
  embeddingDims: row.embeddingDims,
  chunkCount: row.chunkCount,
  errorMessage: row.errorMessage,
  indexedAt: row.indexedAt,
  metadata: toRecord(row.metadata),
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
});

interface RawCandidateRow {
  chunk_id: string;
  document_id: string;
  source_type: KnowledgeSourceType;
  source_id: string;
  title: string;
  subject: string | null;
  visibility: KnowledgeVisibility;
  trust_tier: KnowledgeTrustTier;
  section_title: string | null;
  heading_path: string | null;
  content: string;
  context_header: string;
  start_seconds: number | null;
  end_seconds: number | null;
  source_page: number | null;
  slide_number: number | null;
  metadata: Record<string, unknown>;
  similarity?: number;
  fts_rank?: number;
  embedding_text?: string | null;
}

const buildScopeAndFilterClauses = (
  scope: KnowledgeRetrievalScope,
  filters: KnowledgeSearchFilters | undefined,
  params: unknown[],
): string => {
  const clauses: string[] = [];

  if (scope.mode === 'AUTHOR_PRIVATE') {
    params.push(scope.authorId ?? '');
    clauses.push(`d.author_id = $${params.length}::uuid`);
    if (filters?.trustTiers && filters.trustTiers.length > 0) {
      params.push(filters.trustTiers);
      clauses.push(`d.trust_tier = ANY($${params.length}::"KnowledgeTrustTier"[])`);
    }
  } else if (scope.mode === 'STUDENT_ENROLLED') {
    params.push(scope.enrolledClassGroupIds);
    clauses.push(`d.visibility = 'CLASS_PUBLISHED'::"KnowledgeVisibility"`);
    clauses.push(`d.trust_tier = 'VERIFIED'::"KnowledgeTrustTier"`);
    clauses.push(`d.class_group_ids && $${params.length}::text[]`);
  } else if (scope.mode === 'ADMIN_ALL') {
    if (filters?.trustTiers && filters.trustTiers.length > 0) {
      params.push(filters.trustTiers);
      clauses.push(`d.trust_tier = ANY($${params.length}::"KnowledgeTrustTier"[])`);
    }
    if (filters?.classGroupIds && filters.classGroupIds.length > 0) {
      params.push(filters.classGroupIds);
      clauses.push(`d.class_group_ids && $${params.length}::text[]`);
    }
  }

  if (filters?.sourceTypes && filters.sourceTypes.length > 0) {
    params.push(filters.sourceTypes);
    clauses.push(`d.source_type = ANY($${params.length}::"KnowledgeSourceType"[])`);
  }
  if (filters?.sourceIds && filters.sourceIds.length > 0) {
    params.push(filters.sourceIds);
    clauses.push(`d.source_id = ANY($${params.length}::text[])`);
  }
  if (filters?.subject && filters.subject.trim().length > 0) {
    params.push(filters.subject.trim());
    clauses.push(`lower(coalesce(d.subject, '')) = lower($${params.length})`);
  }

  return clauses.length > 0 ? clauses.join(' AND ') : 'TRUE';
};

/**
 * Builds a safe parameterized OR-prefix tsquery string from natural-language
 * FR/EN/AR/Derja input so FTS still matches useful keywords when a conversational
 * question does not contain every stop word in verbatim order.
 */
const buildSafeOrTsQuery = (rawQuery: string): string => {
  const normalized = rawQuery
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
  const tokens = normalized
    .split(/[^\p{L}\p{N}]+/u)
    .map((t) => t.trim())
    .filter((t) => t.length >= 2);
  const unique = [...new Set(tokens)].slice(0, 12);
  if (unique.length === 0) return '';
  return unique.map((tok) => `${tok.replace(/'/g, '')}:*`).join(' | ');
};

export class PrismaKnowledgeRepositoryAdapter implements KnowledgeRepositoryPort {
  private artifactsEnsured = false;

  constructor(private readonly prisma: PrismaClient = getPrismaClient()) {}

  public async ensureSchemaArtifacts(): Promise<void> {
    if (this.artifactsEnsured) return;
    const pool = getPgPool();
    await pool.query(`CREATE EXTENSION IF NOT EXISTS vector`);
    await pool.query(`CREATE EXTENSION IF NOT EXISTS unaccent`);
    await pool.query(`
      CREATE OR REPLACE FUNCTION smartclass_unaccent(text)
      RETURNS text
      LANGUAGE sql
      IMMUTABLE
      PARALLEL SAFE
      STRICT
      AS $$ SELECT public.unaccent('public.unaccent', $1); $$
    `);
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_knowledge_documents_class_group_ids_gin
        ON knowledge_documents USING gin (class_group_ids)
    `);
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_embedding_hnsw
        ON knowledge_chunks USING hnsw (embedding vector_cosine_ops)
        WITH (m = 16, ef_construction = 64)
        WHERE embedding IS NOT NULL
    `);
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_knowledge_chunks_fts
        ON knowledge_chunks USING gin (
          to_tsvector(
            'simple',
            smartclass_unaccent(
              coalesce(section_title, '') || ' ' || coalesce(context_header, '') || ' ' || content
            )
          )
        )
    `);
    this.artifactsEnsured = true;
  }

  public async findBySource(
    sourceType: KnowledgeSourceType,
    sourceId: string,
  ): Promise<KnowledgeDocumentEntity | null> {
    const row = await this.prisma.knowledgeDocument.findUnique({
      where: { sourceType_sourceId: { sourceType, sourceId } },
    });
    return row ? mapPrismaDoc(row) : null;
  }

  public async findById(documentId: string): Promise<KnowledgeDocumentEntity | null> {
    const row = await this.prisma.knowledgeDocument.findUnique({
      where: { id: documentId },
    });
    return row ? mapPrismaDoc(row) : null;
  }

  public async listBySourcePrefixOrIds(
    sourceTypes: KnowledgeSourceType[],
    sourceIds: string[],
  ): Promise<KnowledgeDocumentEntity[]> {
    const rows = await this.prisma.knowledgeDocument.findMany({
      where: {
        sourceType: { in: sourceTypes },
        sourceId: { in: sourceIds },
      },
    });
    return rows.map(mapPrismaDoc);
  }

  public async upsertDocumentAndChunks(
    params: UpsertKnowledgeDocumentParams,
  ): Promise<KnowledgeDocumentEntity> {
    await this.ensureSchemaArtifacts();

    const doc = await this.prisma.knowledgeDocument.upsert({
      where: {
        sourceType_sourceId: {
          sourceType: params.sourceType,
          sourceId: params.sourceId,
        },
      },
      create: {
        sourceType: params.sourceType,
        sourceId: params.sourceId,
        authorId: params.authorId,
        title: params.title,
        subject: params.subject,
        language: params.language,
        visibility: params.visibility,
        trustTier: params.trustTier,
        classGroupIds: params.classGroupIds,
        contentHash: params.contentHash,
        indexStatus: params.indexStatus,
        embeddingModel: params.embeddingModel,
        embeddingDims: params.embeddingDims,
        chunkCount: params.chunks.length,
        errorMessage: params.errorMessage,
        indexedAt: params.indexedAt,
        metadata: params.metadata as Prisma.InputJsonValue,
      },
      update: {
        authorId: params.authorId,
        title: params.title,
        subject: params.subject,
        language: params.language,
        visibility: params.visibility,
        trustTier: params.trustTier,
        classGroupIds: params.classGroupIds,
        contentHash: params.contentHash,
        indexStatus: params.indexStatus,
        embeddingModel: params.embeddingModel,
        embeddingDims: params.embeddingDims,
        chunkCount: params.chunks.length,
        errorMessage: params.errorMessage,
        indexedAt: params.indexedAt,
        metadata: params.metadata as Prisma.InputJsonValue,
      },
    });

    const pool = getPgPool();
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(`DELETE FROM knowledge_chunks WHERE document_id = $1::uuid`, [doc.id]);

      for (const chunk of params.chunks) {
        const chunkId = randomUUID();
        const vecLiteral = chunk.embedding ? toVectorLiteral(chunk.embedding) : null;
        await client.query(
          `INSERT INTO knowledge_chunks (
             id, document_id, chunk_index, section_title, heading_path,
             content, context_header, token_estimate, start_seconds, end_seconds,
             source_page, slide_number, content_hash, embedding, metadata,
             created_at, updated_at
           ) VALUES (
             $1::uuid, $2::uuid, $3, $4, $5,
             $6, $7, $8, $9, $10,
             $11, $12, $13, $14::vector, $15::jsonb,
             NOW(), NOW()
           )`,
          [
            chunkId,
            doc.id,
            chunk.chunkIndex,
            chunk.sectionTitle,
            chunk.headingPath,
            chunk.content,
            chunk.contextHeader,
            chunk.tokenEstimate,
            chunk.startSeconds,
            chunk.endSeconds,
            chunk.sourcePage,
            chunk.slideNumber,
            chunk.contentHash,
            vecLiteral,
            JSON.stringify(chunk.metadata ?? {}),
          ],
        );
      }

      await client.query('COMMIT');
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }

    return mapPrismaDoc(doc);
  }

  public async updateLifecycleBySource(params: {
    sourceType: KnowledgeSourceType;
    sourceId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<KnowledgeDocumentEntity | null> {
    const existing = await this.prisma.knowledgeDocument.findUnique({
      where: {
        sourceType_sourceId: {
          sourceType: params.sourceType,
          sourceId: params.sourceId,
        },
      },
    });
    if (!existing) return null;

    const updated = await this.prisma.knowledgeDocument.update({
      where: { id: existing.id },
      data: {
        ...(params.visibility !== undefined ? { visibility: params.visibility } : {}),
        ...(params.trustTier !== undefined ? { trustTier: params.trustTier } : {}),
        ...(params.classGroupIds !== undefined ? { classGroupIds: params.classGroupIds } : {}),
      },
    });
    return mapPrismaDoc(updated);
  }

  public async updateLifecycleByCourseId(params: {
    courseId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void> {
    await this.prisma.knowledgeDocument.updateMany({
      where: {
        sourceType: 'COURSE',
        sourceId: params.courseId,
      },
      data: {
        ...(params.visibility !== undefined ? { visibility: params.visibility } : {}),
        ...(params.trustTier !== undefined ? { trustTier: params.trustTier } : {}),
        ...(params.classGroupIds !== undefined ? { classGroupIds: params.classGroupIds } : {}),
      },
    });

    await this.prisma.knowledgeDocument.updateMany({
      where: {
        sourceType: 'COURSE_SECTION',
        metadata: {
          path: ['courseId'],
          equals: params.courseId,
        },
      },
      data: {
        ...(params.visibility !== undefined ? { visibility: params.visibility } : {}),
        ...(params.classGroupIds !== undefined ? { classGroupIds: params.classGroupIds } : {}),
      },
    });
  }

  public async updateLifecycleByRecordingId(params: {
    recordingId: string;
    visibility?: KnowledgeVisibility;
    trustTier?: KnowledgeTrustTier;
    classGroupIds?: string[];
  }): Promise<void> {
    await this.prisma.knowledgeDocument.updateMany({
      where: {
        sourceId: params.recordingId,
        sourceType: {
          in: ['LECTURE_TRANSCRIPT', 'LECTURE_SLIDE', 'LECTURE_PACKAGE', 'RECORDING_SOURCE_DOC'],
        },
      },
      data: {
        ...(params.visibility !== undefined ? { visibility: params.visibility } : {}),
        ...(params.trustTier !== undefined ? { trustTier: params.trustTier } : {}),
        ...(params.classGroupIds !== undefined ? { classGroupIds: params.classGroupIds } : {}),
      },
    });
  }

  public async deleteById(documentId: string): Promise<void> {
    await this.prisma.knowledgeDocument.deleteMany({
      where: { id: documentId },
    });
  }

  public async deleteBySource(sourceType: KnowledgeSourceType, sourceId: string): Promise<void> {
    await this.prisma.knowledgeDocument.deleteMany({
      where: { sourceType, sourceId },
    });
  }

  public async deleteByCourseId(courseId: string): Promise<void> {
    await this.prisma.knowledgeDocument.deleteMany({
      where: {
        OR: [
          { sourceType: 'COURSE', sourceId: courseId },
          {
            sourceType: 'COURSE_SECTION',
            metadata: { path: ['courseId'], equals: courseId },
          },
        ],
      },
    });
  }

  public async deleteByRecordingId(recordingId: string): Promise<void> {
    await this.prisma.knowledgeDocument.deleteMany({
      where: {
        sourceId: recordingId,
        sourceType: {
          in: ['LECTURE_TRANSCRIPT', 'LECTURE_SLIDE', 'LECTURE_PACKAGE', 'RECORDING_SOURCE_DOC'],
        },
      },
    });
  }

  public async listDocuments(params: ListKnowledgeDocumentsParams): Promise<{
    items: KnowledgeDocumentEntity[];
    total: number;
  }> {
    if (params.scope.mode === 'EMPTY') {
      return { items: [], total: 0 };
    }

    const where: Prisma.KnowledgeDocumentWhereInput = {};
    if (params.scope.mode === 'AUTHOR_PRIVATE') {
      where.authorId = params.scope.authorId;
    } else if (params.scope.mode === 'STUDENT_ENROLLED') {
      where.visibility = 'CLASS_PUBLISHED';
      where.trustTier = 'VERIFIED';
      where.classGroupIds = { hasSome: params.scope.enrolledClassGroupIds };
    }

    if (params.sourceTypes && params.sourceTypes.length > 0) {
      where.sourceType = { in: params.sourceTypes };
    }
    if (params.indexStatuses && params.indexStatuses.length > 0) {
      where.indexStatus = { in: params.indexStatuses };
    }
    if (params.subject && params.subject.trim().length > 0) {
      where.subject = { equals: params.subject.trim(), mode: 'insensitive' };
    }

    const skip = Math.max(0, (params.page - 1) * params.limit);
    const take = Math.min(100, Math.max(1, params.limit));

    const [rows, total] = await Promise.all([
      this.prisma.knowledgeDocument.findMany({
        where,
        orderBy: [{ updatedAt: 'desc' }],
        skip,
        take,
      }),
      this.prisma.knowledgeDocument.count({ where }),
    ]);

    return {
      items: rows.map(mapPrismaDoc),
      total,
    };
  }

  public async listPendingOrFailedDocuments(limit = 50): Promise<KnowledgeDocumentEntity[]> {
    const rows = await this.prisma.knowledgeDocument.findMany({
      where: {
        indexStatus: { in: ['PENDING', 'INDEXING', 'PENDING_EMBEDDING', 'FAILED'] },
      },
      orderBy: [{ updatedAt: 'asc' }],
      take: limit,
    });
    return rows.map(mapPrismaDoc);
  }

  public async searchVectorCandidates(params: {
    scope: KnowledgeRetrievalScope;
    queryVector: number[];
    filters?: KnowledgeSearchFilters;
    limit: number;
  }): Promise<VectorCandidate[]> {
    if (params.scope.mode === 'EMPTY') return [];
    await this.ensureSchemaArtifacts();

    const sqlParams: unknown[] = [toVectorLiteral(params.queryVector)];
    const whereClause = buildScopeAndFilterClauses(params.scope, params.filters, sqlParams);
    sqlParams.push(Math.max(1, Math.min(60, params.limit)));
    const limitParamIdx = sqlParams.length;

    const pool = getPgPool();
    const { rows } = await pool.query<RawCandidateRow>(
      `SELECT
         c.id::text AS chunk_id,
         d.id::text AS document_id,
         d.source_type,
         d.source_id,
         d.title,
         d.subject,
         d.visibility,
         d.trust_tier,
         c.section_title,
         c.heading_path,
         c.content,
         c.context_header,
         c.start_seconds,
         c.end_seconds,
         c.source_page,
         c.slide_number,
         c.metadata,
         c.embedding::text AS embedding_text,
         (1 - (c.embedding <=> $1::vector))::double precision AS similarity
       FROM knowledge_chunks c
       INNER JOIN knowledge_documents d ON d.id = c.document_id
       WHERE c.embedding IS NOT NULL
         AND ${whereClause}
       ORDER BY c.embedding <=> $1::vector ASC
       LIMIT $${limitParamIdx}`,
      sqlParams,
    );

    return rows.map((row) => ({
      chunkId: row.chunk_id,
      documentId: row.document_id,
      sourceType: row.source_type,
      sourceId: row.source_id,
      title: row.title,
      subject: row.subject,
      visibility: row.visibility,
      trustTier: row.trust_tier,
      sectionTitle: row.section_title,
      headingPath: row.heading_path,
      content: row.content,
      contextHeader: row.context_header,
      startSeconds: row.start_seconds,
      endSeconds: row.end_seconds,
      sourcePage: row.source_page,
      slideNumber: row.slide_number,
      metadata: toRecord(row.metadata),
      vectorSimilarity: Number(row.similarity ?? 0),
      embedding: parseVectorText(row.embedding_text),
    }));
  }

  public async searchFtsCandidates(params: {
    scope: KnowledgeRetrievalScope;
    query: string;
    filters?: KnowledgeSearchFilters;
    limit: number;
  }): Promise<FtsCandidate[]> {
    if (params.scope.mode === 'EMPTY') return [];
    const trimmed = params.query.trim();
    if (!trimmed) return [];

    await this.ensureSchemaArtifacts();
    const orQuery = buildSafeOrTsQuery(trimmed);

    const sqlParams: unknown[] = [trimmed, orQuery || trimmed];
    const whereClause = buildScopeAndFilterClauses(params.scope, params.filters, sqlParams);
    sqlParams.push(Math.max(1, Math.min(60, params.limit)));
    const limitParamIdx = sqlParams.length;

    const pool = getPgPool();
    const { rows } = await pool.query<RawCandidateRow>(
      `WITH query_terms AS (
         SELECT
           websearch_to_tsquery('simple', smartclass_unaccent($1)) AS q_strict,
           to_tsquery('simple', $2) AS q_or
       ),
       doc_vectors AS (
         SELECT
           c.id::text AS chunk_id,
           d.id::text AS document_id,
           d.source_type,
           d.source_id,
           d.title,
           d.subject,
           d.visibility,
           d.trust_tier,
           c.section_title,
           c.heading_path,
           c.content,
           c.context_header,
           c.start_seconds,
           c.end_seconds,
           c.source_page,
           c.slide_number,
           c.metadata,
           to_tsvector(
             'simple',
             smartclass_unaccent(
               coalesce(c.section_title, '') || ' ' || coalesce(c.context_header, '') || ' ' || c.content
             )
           ) AS tsv
         FROM knowledge_chunks c
         INNER JOIN knowledge_documents d ON d.id = c.document_id
         WHERE ${whereClause}
       )
       SELECT
         dv.chunk_id,
         dv.document_id,
         dv.source_type,
         dv.source_id,
         dv.title,
         dv.subject,
         dv.visibility,
         dv.trust_tier,
         dv.section_title,
         dv.heading_path,
         dv.content,
         dv.context_header,
         dv.start_seconds,
         dv.end_seconds,
         dv.source_page,
         dv.slide_number,
         dv.metadata,
         (
           coalesce(ts_rank_cd(dv.tsv, qt.q_strict), 0) * 2.0 +
           coalesce(ts_rank_cd(dv.tsv, qt.q_or), 0)
         )::double precision AS fts_rank
       FROM doc_vectors dv, query_terms qt
       WHERE (qt.q_strict <> ''::tsquery AND dv.tsv @@ qt.q_strict)
          OR (qt.q_or <> ''::tsquery AND dv.tsv @@ qt.q_or)
       ORDER BY fts_rank DESC
       LIMIT $${limitParamIdx}`,
      sqlParams,
    );

    return rows.map((row) => ({
      chunkId: row.chunk_id,
      documentId: row.document_id,
      sourceType: row.source_type,
      sourceId: row.source_id,
      title: row.title,
      subject: row.subject,
      visibility: row.visibility,
      trustTier: row.trust_tier,
      sectionTitle: row.section_title,
      headingPath: row.heading_path,
      content: row.content,
      contextHeader: row.context_header,
      startSeconds: row.start_seconds,
      endSeconds: row.end_seconds,
      sourcePage: row.source_page,
      slideNumber: row.slide_number,
      metadata: toRecord(row.metadata),
      ftsRank: Number(row.fts_rank ?? 0),
    }));
  }

  public async logRetrieval(params: LogKnowledgeRetrievalParams): Promise<void> {
    await this.prisma.knowledgeRetrievalLog.create({
      data: {
        userId: params.userId,
        userRole: params.userRole,
        query: params.query.slice(0, 1000),
        queryHash: params.queryHash,
        searchMode: params.searchMode,
        degradedReason: params.degradedReason,
        filters: params.filters as Prisma.InputJsonValue,
        candidateCount: params.candidateCount,
        returnedCount: params.returnedCount,
        topScore: params.topScore,
        embeddingLatencyMs: params.embeddingLatencyMs,
        searchLatencyMs: params.searchLatencyMs,
        totalLatencyMs: params.totalLatencyMs,
      },
    });
  }

  public async getAggregateCounts(): Promise<KnowledgeStatusReport['counts']> {
    const [docsByType, docsByStatus, docsByTrust, docsByVisibility, totalChunks, embeddedRows] =
      await Promise.all([
        this.prisma.knowledgeDocument.groupBy({ by: ['sourceType'], _count: { _all: true } }),
        this.prisma.knowledgeDocument.groupBy({ by: ['indexStatus'], _count: { _all: true } }),
        this.prisma.knowledgeDocument.groupBy({ by: ['trustTier'], _count: { _all: true } }),
        this.prisma.knowledgeDocument.groupBy({ by: ['visibility'], _count: { _all: true } }),
        this.prisma.knowledgeChunk.count(),
        getPgPool().query<{ count: string }>(
          `SELECT COUNT(*)::text AS count FROM knowledge_chunks WHERE embedding IS NOT NULL`,
        ),
      ]);

    const toMap = <K extends string>(
      rows: Array<{ _count: { _all: number } } & Record<string, unknown>>,
      key: string,
    ): Record<string, number> => {
      const acc: Record<string, number> = {};
      for (const r of rows) {
        acc[String(r[key] as K)] = r._count._all;
      }
      return acc;
    };

    const bySourceType = toMap(docsByType as never, 'sourceType');
    const byStatus = toMap(docsByStatus as never, 'indexStatus');
    const byTrustTier = toMap(docsByTrust as never, 'trustTier');
    const byVisibility = toMap(docsByVisibility as never, 'visibility');
    const totalDocuments = Object.values(byStatus).reduce((sum, n) => sum + n, 0);

    return {
      totalDocuments,
      totalChunks,
      embeddedChunks: Number.parseInt(embeddedRows.rows[0]?.count ?? '0', 10) || 0,
      pendingEmbeddingDocuments: byStatus['PENDING_EMBEDDING'] ?? 0,
      failedDocuments: byStatus['FAILED'] ?? 0,
      bySourceType,
      byStatus,
      byTrustTier,
      byVisibility,
    };
  }

  public async getRecentRetrievalStats(): Promise<KnowledgeStatusReport['recentRetrievals']> {
    const since = new Date(Date.now() - 24 * 60 * 60 * 1000);
    const grouped = await this.prisma.knowledgeRetrievalLog.groupBy({
      by: ['searchMode'],
      where: { createdAt: { gte: since } },
      _count: { _all: true },
    });

    const map: Record<KnowledgeSearchMode, number> = {
      HYBRID: 0,
      FTS_ONLY: 0,
      VECTOR_ONLY: 0,
    };
    for (const row of grouped) {
      map[row.searchMode] = row._count._all;
    }

    return {
      totalLast24h: map.HYBRID + map.FTS_ONLY + map.VECTOR_ONLY,
      hybridCount: map.HYBRID,
      ftsOnlyCount: map.FTS_ONLY,
      vectorOnlyCount: map.VECTOR_ONLY,
    };
  }
}
