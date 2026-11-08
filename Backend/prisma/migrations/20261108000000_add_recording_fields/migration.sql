-- AlterTable
ALTER TABLE "video_sessions" ADD COLUMN "recording_url" TEXT,
ADD COLUMN "recording_egress_id" VARCHAR(100),
ADD COLUMN "transcript" TEXT;
