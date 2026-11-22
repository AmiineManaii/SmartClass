-- Unified SmartClass Knowledge Engine (RAG Core)
-- Preserves legacy course_passages intact during Phase 1 migration.

CREATE EXTENSION IF NOT EXISTS vector;
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION smartclass_unaccent(text)
RETURNS text
LANGUAGE sql
IMMUTABLE
PARALLEL SAFE
STRICT
AS $$
  SELECT public.unaccent('public.unaccent', $1);
$$;

DO $$ BEGIN
  CREATE TYPE "KnowledgeSourceType" AS ENUM (
    'COURSE',
    'COURSE_SECTION',
    'LECTURE_TRANSCRIPT',
    'LECTURE_SLIDE',
    'LECTURE_PACKAGE',
    'RECORDING_SOURCE_DOC',
    'UPLOADED_DOCUMENT'
  );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE "KnowledgeVisibility" AS ENUM (
    'PRIVATE_AUTHOR',
    'CLASS_PUBLISHED',
    'INSTITUTION_SHARED'
  );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE "KnowledgeTrustTier" AS ENUM (
    'DRAFT_AI',
    'VERIFIED'
  );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE "KnowledgeIndexStatus" AS ENUM (
    'PENDING',
    'INDEXING',
    'INDEXED',
    'PENDING_EMBEDDING',
    'FAILED'
  );
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
  CREATE TYPE "KnowledgeSearchMode" AS ENUM (
    'HYBRID',
    'FTS_ONLY',
    'VECTOR_ONLY'
  );
EXCEPTION WHEN duplicate_object THEN null; END $$;

CREATE TABLE IF NOT EXISTS "knowledge_documents" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "source_type" "KnowledgeSourceType" NOT NULL,
  "source_id" TEXT NOT NULL,
  "author_id" UUID NOT NULL,
  "title" TEXT NOT NULL,
  "subject" TEXT,
  "language" TEXT NOT NULL DEFAULT 'fr',
  "visibility" "KnowledgeVisibility" NOT NULL DEFAULT 'PRIVATE_AUTHOR',
  "trust_tier" "KnowledgeTrustTier" NOT NULL DEFAULT 'DRAFT_AI',
  "class_group_ids" TEXT[] NOT NULL DEFAULT ARRAY[]::TEXT[],
  "content_hash" TEXT NOT NULL,
  "index_status" "KnowledgeIndexStatus" NOT NULL DEFAULT 'PENDING',
  "embedding_model" TEXT,
  "embedding_dims" INTEGER NOT NULL DEFAULT 768,
  "chunk_count" INTEGER NOT NULL DEFAULT 0,
  "error_message" TEXT,
  "indexed_at" TIMESTAMPTZ,
  "metadata" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "knowledge_documents_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "knowledge_documents_author_id_fkey"
    FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "knowledge_chunks" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "document_id" UUID NOT NULL,
  "chunk_index" INTEGER NOT NULL,
  "section_title" TEXT,
  "heading_path" TEXT,
  "content" TEXT NOT NULL,
  "context_header" TEXT NOT NULL DEFAULT '',
  "token_estimate" INTEGER NOT NULL DEFAULT 0,
  "start_seconds" INTEGER,
  "end_seconds" INTEGER,
  "source_page" INTEGER,
  "slide_number" INTEGER,
  "content_hash" TEXT NOT NULL,
  "embedding" vector(768),
  "metadata" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "knowledge_chunks_pkey" PRIMARY KEY ("id"),
  CONSTRAINT "knowledge_chunks_document_id_fkey"
    FOREIGN KEY ("document_id") REFERENCES "knowledge_documents"("id") ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS "knowledge_retrieval_logs" (
  "id" UUID NOT NULL DEFAULT gen_random_uuid(),
  "user_id" UUID NOT NULL,
  "user_role" "Role" NOT NULL,
  "query" TEXT NOT NULL,
  "query_hash" TEXT NOT NULL,
  "search_mode" "KnowledgeSearchMode" NOT NULL,
  "degraded_reason" TEXT,
  "filters" JSONB NOT NULL DEFAULT '{}'::jsonb,
  "candidate_count" INTEGER NOT NULL DEFAULT 0,
  "returned_count" INTEGER NOT NULL DEFAULT 0,
  "top_score" DOUBLE PRECISION,
  "embedding_latency_ms" INTEGER,
  "search_latency_ms" INTEGER NOT NULL DEFAULT 0,
  "total_latency_ms" INTEGER NOT NULL DEFAULT 0,
  "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "knowledge_retrieval_logs_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "knowledge_documents_source_type_source_id_key"
  ON "knowledge_documents" ("source_type", "source_id");
CREATE INDEX IF NOT EXISTS "knowledge_documents_author_id_idx"
  ON "knowledge_documents" ("author_id");
CREATE INDEX IF NOT EXISTS "knowledge_documents_visibility_trust_tier_idx"
  ON "knowledge_documents" ("visibility", "trust_tier");
CREATE INDEX IF NOT EXISTS "knowledge_documents_index_status_idx"
  ON "knowledge_documents" ("index_status");
CREATE INDEX IF NOT EXISTS "knowledge_documents_source_type_idx"
  ON "knowledge_documents" ("source_type");
CREATE INDEX IF NOT EXISTS "idx_knowledge_documents_class_group_ids_gin"
  ON "knowledge_documents" USING gin ("class_group_ids");

CREATE UNIQUE INDEX IF NOT EXISTS "knowledge_chunks_document_id_chunk_index_key"
  ON "knowledge_chunks" ("document_id", "chunk_index");
CREATE INDEX IF NOT EXISTS "knowledge_chunks_document_id_idx"
  ON "knowledge_chunks" ("document_id");
CREATE INDEX IF NOT EXISTS "idx_knowledge_chunks_embedding_hnsw"
  ON "knowledge_chunks" USING hnsw ("embedding" vector_cosine_ops)
  WITH (m = 16, ef_construction = 64)
  WHERE "embedding" IS NOT NULL;
CREATE INDEX IF NOT EXISTS "idx_knowledge_chunks_fts"
  ON "knowledge_chunks" USING gin (
    to_tsvector(
      'simple',
      smartclass_unaccent(
        coalesce("section_title", '') || ' ' || coalesce("context_header", '') || ' ' || "content"
      )
    )
  );

CREATE INDEX IF NOT EXISTS "knowledge_retrieval_logs_user_id_created_at_idx"
  ON "knowledge_retrieval_logs" ("user_id", "created_at");
CREATE INDEX IF NOT EXISTS "knowledge_retrieval_logs_search_mode_created_at_idx"
  ON "knowledge_retrieval_logs" ("search_mode", "created_at");
