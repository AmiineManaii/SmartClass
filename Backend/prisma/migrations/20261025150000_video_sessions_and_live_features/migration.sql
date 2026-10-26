-- CreateEnum
CREATE TYPE "VideoSessionStatus" AS ENUM ('SCHEDULED', 'IN_PROGRESS', 'COMPLETED', 'CANCELED');

-- CreateTable
CREATE TABLE "video_sessions" (
    "id" UUID NOT NULL,
    "class_group_id" UUID NOT NULL,
    "host_id" UUID,
    "subject" VARCHAR(100),
    "title" VARCHAR(200) NOT NULL,
    "description" TEXT,
    "starts_at" TIMESTAMPTZ NOT NULL,
    "ends_at" TIMESTAMPTZ NOT NULL,
    "started_at" TIMESTAMPTZ,
    "ended_at" TIMESTAMPTZ,
    "status" "VideoSessionStatus" NOT NULL DEFAULT 'SCHEDULED',
    "room_name" TEXT NOT NULL,
    "join_opens_minutes_before" INTEGER NOT NULL DEFAULT 5,
    "chat_enabled" BOOLEAN NOT NULL DEFAULT true,
    "timetable_slot_id" UUID,
    "course_id" UUID,
    "cancel_reason" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "video_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "session_participants" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "joined_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "left_at" TIMESTAMPTZ,

    CONSTRAINT "session_participants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "session_chat_messages" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "sender_id" UUID NOT NULL,
    "client_message_id" UUID NOT NULL,
    "content" VARCHAR(2000) NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "session_chat_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "session_participant_removals" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "removed_by_id" UUID NOT NULL,
    "reason" VARCHAR(500),
    "removed_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "session_participant_removals_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "video_sessions_room_name_key" ON "video_sessions"("room_name");
CREATE INDEX "video_sessions_class_group_id_starts_at_idx" ON "video_sessions"("class_group_id", "starts_at");
CREATE INDEX "video_sessions_host_id_idx" ON "video_sessions"("host_id");
CREATE INDEX "video_sessions_status_starts_at_idx" ON "video_sessions"("status", "starts_at");

-- CreateIndex
CREATE INDEX "session_participants_session_id_user_id_idx" ON "session_participants"("session_id", "user_id");

-- CreateIndex
CREATE UNIQUE INDEX "session_chat_messages_session_id_sender_id_client_message__key" ON "session_chat_messages"("session_id", "sender_id", "client_message_id");
CREATE INDEX "session_chat_messages_session_id_created_at_idx" ON "session_chat_messages"("session_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "session_participant_removals_session_id_user_id_key" ON "session_participant_removals"("session_id", "user_id");

-- AddForeignKey
ALTER TABLE "video_sessions" ADD CONSTRAINT "video_sessions_class_group_id_fkey" FOREIGN KEY ("class_group_id") REFERENCES "class_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "video_sessions" ADD CONSTRAINT "video_sessions_host_id_fkey" FOREIGN KEY ("host_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "video_sessions" ADD CONSTRAINT "video_sessions_timetable_slot_id_fkey" FOREIGN KEY ("timetable_slot_id") REFERENCES "timetable_slots"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "video_sessions" ADD CONSTRAINT "video_sessions_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "courses"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "session_participants" ADD CONSTRAINT "session_participants_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "video_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "session_participants" ADD CONSTRAINT "session_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "session_chat_messages" ADD CONSTRAINT "session_chat_messages_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "video_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "session_chat_messages" ADD CONSTRAINT "session_chat_messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "session_participant_removals" ADD CONSTRAINT "session_participant_removals_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "video_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "session_participant_removals" ADD CONSTRAINT "session_participant_removals_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "session_participant_removals" ADD CONSTRAINT "session_participant_removals_removed_by_id_fkey" FOREIGN KEY ("removed_by_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
