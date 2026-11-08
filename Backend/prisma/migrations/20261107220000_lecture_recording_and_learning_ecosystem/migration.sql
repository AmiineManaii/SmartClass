-- CreateEnum (idempotent)
DO $$ BEGIN
    CREATE TYPE "RecordingStatus" AS ENUM (
        'NOT_STARTED',
        'STARTING',
        'RECORDING',
        'FINALIZING',
        'RECORDED',
        'PROCESSING',
        'READY_FOR_REVIEW',
        'APPROVED',
        'PUBLISHED',
        'FAILED',
        'DELETED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "ProcessingJobStatus" AS ENUM (
        'QUEUED',
        'RUNNING',
        'SUCCEEDED',
        'FAILED',
        'CANCELED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "ProcessingStage" AS ENUM (
        'VALIDATION',
        'AUDIO_EXTRACTION',
        'TRANSCRIPTION',
        'VISUAL_ANALYSIS',
        'DOCUMENT_ANALYSIS',
        'TEMPORAL_ALIGNMENT',
        'LESSON_GENERATION',
        'QUALITY_VALIDATION',
        'COMPLETED'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "StudyArtifactKind" AS ENUM (
        'SUMMARY',
        'QUIZ',
        'FLASHCARDS'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- CreateTable: recordings
CREATE TABLE IF NOT EXISTS "recordings" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "session_id" UUID NOT NULL,
    "class_group_id" UUID NOT NULL,
    "host_id" UUID,
    "status" "RecordingStatus" NOT NULL DEFAULT 'NOT_STARTED',
    "egress_id" TEXT,
    "storage_key" TEXT,
    "mime_type" TEXT NOT NULL DEFAULT 'video/mp4',
    "size_bytes" BIGINT,
    "duration_seconds" INTEGER,
    "width" INTEGER,
    "height" INTEGER,
    "thumbnail_key" TEXT,
    "source_doc_key" TEXT,
    "source_doc_title" TEXT,
    "source_doc_text" TEXT,
    "error_code" TEXT,
    "error_message" TEXT,
    "started_at" TIMESTAMPTZ,
    "stopped_at" TIMESTAMPTZ,
    "published_at" TIMESTAMPTZ,
    "processing_version" INTEGER NOT NULL DEFAULT 1,
    "ai_model_used" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recordings_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "recordings_session_id_key" ON "recordings"("session_id");
CREATE UNIQUE INDEX IF NOT EXISTS "recordings_egress_id_key" ON "recordings"("egress_id");
CREATE INDEX IF NOT EXISTS "recordings_class_group_id_status_idx" ON "recordings"("class_group_id", "status");
CREATE INDEX IF NOT EXISTS "recordings_host_id_idx" ON "recordings"("host_id");
CREATE INDEX IF NOT EXISTS "recordings_status_idx" ON "recordings"("status");

-- CreateTable: recording_processing_jobs
CREATE TABLE IF NOT EXISTS "recording_processing_jobs" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "status" "ProcessingJobStatus" NOT NULL DEFAULT 'QUEUED',
    "stage" "ProcessingStage" NOT NULL DEFAULT 'VALIDATION',
    "progress" INTEGER NOT NULL DEFAULT 0,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "max_attempts" INTEGER NOT NULL DEFAULT 3,
    "locked_at" TIMESTAMPTZ,
    "worker_id" TEXT,
    "error_message" TEXT,
    "stage_logs" JSONB NOT NULL DEFAULT '[]',
    "started_at" TIMESTAMPTZ,
    "completed_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recording_processing_jobs_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "recording_processing_jobs_recording_id_created_at_idx" ON "recording_processing_jobs"("recording_id", "created_at");
CREATE INDEX IF NOT EXISTS "recording_processing_jobs_status_created_at_idx" ON "recording_processing_jobs"("status", "created_at");

-- CreateTable: recording_transcripts
CREATE TABLE IF NOT EXISTS "recording_transcripts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'fr',
    "full_text" TEXT NOT NULL,
    "vtt_content" TEXT NOT NULL DEFAULT '',
    "srt_content" TEXT NOT NULL DEFAULT '',
    "quality_score" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "model_used" TEXT,
    "updated_by_id" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recording_transcripts_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "recording_transcripts_recording_id_key" ON "recording_transcripts"("recording_id");

-- CreateTable: recording_transcript_segments
CREATE TABLE IF NOT EXISTS "recording_transcript_segments" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "transcript_id" UUID NOT NULL,
    "recording_id" UUID NOT NULL,
    "order_index" INTEGER NOT NULL,
    "start_seconds" DOUBLE PRECISION NOT NULL,
    "end_seconds" DOUBLE PRECISION NOT NULL,
    "text" TEXT NOT NULL,
    "speaker" TEXT,
    "confidence" DOUBLE PRECISION NOT NULL DEFAULT 1.0,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recording_transcript_segments_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "recording_transcript_segments_recording_id_order_index_idx" ON "recording_transcript_segments"("recording_id", "order_index");
CREATE INDEX IF NOT EXISTS "recording_transcript_segments_recording_id_start_seconds_idx" ON "recording_transcript_segments"("recording_id", "start_seconds");

-- CreateTable: recording_slide_frames
CREATE TABLE IF NOT EXISTS "recording_slide_frames" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "timestamp_seconds" DOUBLE PRECISION NOT NULL,
    "storage_key" TEXT,
    "perceptual_hash" TEXT,
    "ocr_text" TEXT NOT NULL DEFAULT '',
    "visual_summary" TEXT NOT NULL DEFAULT '',
    "source_page" INTEGER,
    "model_used" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recording_slide_frames_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "recording_slide_frames_recording_id_timestamp_seconds_idx" ON "recording_slide_frames"("recording_id", "timestamp_seconds");

-- CreateTable: recording_chapters
CREATE TABLE IF NOT EXISTS "recording_chapters" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "order_index" INTEGER NOT NULL,
    "title" TEXT NOT NULL,
    "summary" TEXT NOT NULL DEFAULT '',
    "start_seconds" DOUBLE PRECISION NOT NULL,
    "end_seconds" DOUBLE PRECISION NOT NULL,
    "key_concepts" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "slide_frame_id" UUID,
    "source_page" INTEGER,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "recording_chapters_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "recording_chapters_recording_id_order_index_idx" ON "recording_chapters"("recording_id", "order_index");

-- CreateTable: lesson_packages
CREATE TABLE IF NOT EXISTS "lesson_packages" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "structured_notes" TEXT NOT NULL DEFAULT '',
    "general_summary" TEXT NOT NULL DEFAULT '',
    "key_concepts" JSONB NOT NULL DEFAULT '[]',
    "definitions" JSONB NOT NULL DEFAULT '[]',
    "important_examples" JSONB NOT NULL DEFAULT '[]',
    "learning_objectives" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "formulas_and_rules" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "important_moments" JSONB NOT NULL DEFAULT '[]',
    "revision_sheet" TEXT NOT NULL DEFAULT '',
    "mind_map_mermaid" TEXT NOT NULL DEFAULT '',
    "suggested_study_order" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "flashcards" JSONB NOT NULL DEFAULT '[]',
    "quizzes" JSONB NOT NULL DEFAULT '[]',
    "quality_report" JSONB NOT NULL DEFAULT '{}',
    "primary_model" TEXT,
    "secondary_model" TEXT,
    "approved_by_id" UUID,
    "approved_at" TIMESTAMPTZ,
    "published_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lesson_packages_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "lesson_packages_recording_id_key" ON "lesson_packages"("recording_id");

-- CreateTable: lesson_package_versions
CREATE TABLE IF NOT EXISTS "lesson_package_versions" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "lesson_package_id" UUID NOT NULL,
    "version" INTEGER NOT NULL,
    "snapshot" JSONB NOT NULL,
    "edited_by_id" UUID,
    "change_summary" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lesson_package_versions_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "lesson_package_versions_lesson_package_id_version_idx" ON "lesson_package_versions"("lesson_package_id", "version");

-- CreateTable: student_lesson_artifacts
CREATE TABLE IF NOT EXISTS "student_lesson_artifacts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "kind" "StudyArtifactKind" NOT NULL,
    "title" TEXT NOT NULL,
    "language" TEXT NOT NULL DEFAULT 'fr',
    "chapter_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "config" JSONB NOT NULL DEFAULT '{}',
    "content" JSONB NOT NULL DEFAULT '{}',
    "model_used" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_lesson_artifacts_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "student_lesson_artifacts_recording_id_user_id_kind_idx" ON "student_lesson_artifacts"("recording_id", "user_id", "kind");

-- CreateTable: student_quiz_attempts
CREATE TABLE IF NOT EXISTS "student_quiz_attempts" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "artifact_id" UUID NOT NULL,
    "recording_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "score" INTEGER NOT NULL,
    "total_questions" INTEGER NOT NULL,
    "answers" JSONB NOT NULL DEFAULT '[]',
    "results" JSONB NOT NULL DEFAULT '[]',
    "weak_topics" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "completed_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_quiz_attempts_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "student_quiz_attempts_recording_id_user_id_idx" ON "student_quiz_attempts"("recording_id", "user_id");

-- CreateTable: student_lesson_progresses
CREATE TABLE IF NOT EXISTS "student_lesson_progresses" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "last_position_seconds" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "watched_seconds" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "completed_chapters" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "flashcard_known_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "flashcard_review_ids" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_lesson_progresses_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "student_lesson_progresses_recording_id_user_id_key" ON "student_lesson_progresses"("recording_id", "user_id");

-- CreateTable: student_lesson_bookmarks
CREATE TABLE IF NOT EXISTS "student_lesson_bookmarks" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "timestamp_seconds" DOUBLE PRECISION NOT NULL,
    "label" TEXT NOT NULL,
    "chapter_title" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_lesson_bookmarks_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "student_lesson_bookmarks_recording_id_user_id_timestamp_sec_idx" ON "student_lesson_bookmarks"("recording_id", "user_id", "timestamp_seconds");

-- CreateTable: student_lesson_notes
CREATE TABLE IF NOT EXISTS "student_lesson_notes" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "timestamp_seconds" DOUBLE PRECISION,
    "content" TEXT NOT NULL,
    "highlight_text" TEXT,
    "chapter_title" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "student_lesson_notes_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "student_lesson_notes_recording_id_user_id_created_at_idx" ON "student_lesson_notes"("recording_id", "user_id", "created_at");

-- CreateTable: lesson_tutor_conversations
CREATE TABLE IF NOT EXISTS "lesson_tutor_conversations" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "recording_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "title" TEXT NOT NULL DEFAULT 'Discussion Tuteur IA',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lesson_tutor_conversations_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "lesson_tutor_conversations_recording_id_user_id_updated_at_idx" ON "lesson_tutor_conversations"("recording_id", "user_id", "updated_at");

-- CreateTable: lesson_tutor_messages
CREATE TABLE IF NOT EXISTS "lesson_tutor_messages" (
    "id" UUID NOT NULL DEFAULT gen_random_uuid(),
    "conversation_id" UUID NOT NULL,
    "role" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "citations" JSONB NOT NULL DEFAULT '[]',
    "model_used" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "lesson_tutor_messages_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "lesson_tutor_messages_conversation_id_created_at_idx" ON "lesson_tutor_messages"("conversation_id", "created_at");

-- AddForeignKeys (idempotent)
DO $$ BEGIN
    ALTER TABLE "recordings" ADD CONSTRAINT "recordings_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "video_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "recordings" ADD CONSTRAINT "recordings_class_group_id_fkey" FOREIGN KEY ("class_group_id") REFERENCES "class_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "recordings" ADD CONSTRAINT "recordings_host_id_fkey" FOREIGN KEY ("host_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "recording_processing_jobs" ADD CONSTRAINT "recording_processing_jobs_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "recording_transcripts" ADD CONSTRAINT "recording_transcripts_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "recording_transcript_segments" ADD CONSTRAINT "recording_transcript_segments_transcript_id_fkey" FOREIGN KEY ("transcript_id") REFERENCES "recording_transcripts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "recording_transcript_segments" ADD CONSTRAINT "recording_transcript_segments_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "recording_slide_frames" ADD CONSTRAINT "recording_slide_frames_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "recording_chapters" ADD CONSTRAINT "recording_chapters_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "lesson_packages" ADD CONSTRAINT "lesson_packages_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "lesson_package_versions" ADD CONSTRAINT "lesson_package_versions_lesson_package_id_fkey" FOREIGN KEY ("lesson_package_id") REFERENCES "lesson_packages"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_lesson_artifacts" ADD CONSTRAINT "student_lesson_artifacts_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_lesson_artifacts" ADD CONSTRAINT "student_lesson_artifacts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_quiz_attempts" ADD CONSTRAINT "student_quiz_attempts_artifact_id_fkey" FOREIGN KEY ("artifact_id") REFERENCES "student_lesson_artifacts"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_quiz_attempts" ADD CONSTRAINT "student_quiz_attempts_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_quiz_attempts" ADD CONSTRAINT "student_quiz_attempts_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_lesson_progresses" ADD CONSTRAINT "student_lesson_progresses_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_lesson_progresses" ADD CONSTRAINT "student_lesson_progresses_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_lesson_bookmarks" ADD CONSTRAINT "student_lesson_bookmarks_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_lesson_bookmarks" ADD CONSTRAINT "student_lesson_bookmarks_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_lesson_notes" ADD CONSTRAINT "student_lesson_notes_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "student_lesson_notes" ADD CONSTRAINT "student_lesson_notes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "lesson_tutor_conversations" ADD CONSTRAINT "lesson_tutor_conversations_recording_id_fkey" FOREIGN KEY ("recording_id") REFERENCES "recordings"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "lesson_tutor_conversations" ADD CONSTRAINT "lesson_tutor_conversations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "lesson_tutor_messages" ADD CONSTRAINT "lesson_tutor_messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "lesson_tutor_conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;
EXCEPTION WHEN duplicate_object THEN null; END $$;

