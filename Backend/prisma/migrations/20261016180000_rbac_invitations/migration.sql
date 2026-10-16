-- AlterEnum
ALTER TYPE "ClassStatus" ADD VALUE 'ARCHIVED';

-- CreateEnum
CREATE TYPE "TeacherApprovalStatus" AS ENUM ('PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "InvitationStatus" AS ENUM ('ACTIVE', 'REVOKED', 'EXPIRED');

-- AlterTable
ALTER TABLE "users" ADD COLUMN "teacher_approval_status" "TeacherApprovalStatus";

-- CreateIndex
CREATE INDEX "users_teacher_approval_status_idx" ON "users"("teacher_approval_status");

-- AlterTable
ALTER TABLE "class_groups" ADD COLUMN "academic_year" TEXT;
ALTER TABLE "class_groups" ADD COLUMN "is_virtual" BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE "class_groups" ADD COLUMN "owner_id" UUID;

-- CreateIndex
CREATE INDEX "class_groups_owner_id_idx" ON "class_groups"("owner_id");
CREATE INDEX "class_groups_is_virtual_idx" ON "class_groups"("is_virtual");

-- AddForeignKey
ALTER TABLE "class_groups" ADD CONSTRAINT "class_groups_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- CreateTable
CREATE TABLE "course_class_groups" (
    "id" UUID NOT NULL,
    "course_id" UUID NOT NULL,
    "class_group_id" UUID NOT NULL,
    "assigned_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "course_class_groups_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "course_class_groups_course_id_class_group_id_key" ON "course_class_groups"("course_id", "class_group_id");
CREATE INDEX "course_class_groups_course_id_idx" ON "course_class_groups"("course_id");
CREATE INDEX "course_class_groups_class_group_id_idx" ON "course_class_groups"("class_group_id");

-- AddForeignKey
ALTER TABLE "course_class_groups" ADD CONSTRAINT "course_class_groups_course_id_fkey" FOREIGN KEY ("course_id") REFERENCES "courses"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "course_class_groups" ADD CONSTRAINT "course_class_groups_class_group_id_fkey" FOREIGN KEY ("class_group_id") REFERENCES "class_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateTable
CREATE TABLE "class_invitations" (
    "id" UUID NOT NULL,
    "class_group_id" UUID NOT NULL,
    "code_hash" TEXT NOT NULL,
    "code_prefix" TEXT,
    "creator_id" UUID NOT NULL,
    "status" "InvitationStatus" NOT NULL DEFAULT 'ACTIVE',
    "expires_at" TIMESTAMPTZ,
    "max_uses" INTEGER,
    "used_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "class_invitations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "class_invitations_code_hash_key" ON "class_invitations"("code_hash");
CREATE INDEX "class_invitations_class_group_id_idx" ON "class_invitations"("class_group_id");
CREATE INDEX "class_invitations_status_idx" ON "class_invitations"("status");

-- AddForeignKey
ALTER TABLE "class_invitations" ADD CONSTRAINT "class_invitations_class_group_id_fkey" FOREIGN KEY ("class_group_id") REFERENCES "class_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "class_invitations" ADD CONSTRAINT "class_invitations_creator_id_fkey" FOREIGN KEY ("creator_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" UUID NOT NULL,
    "user_id" UUID,
    "action" TEXT NOT NULL,
    "target_type" TEXT NOT NULL,
    "target_id" TEXT,
    "details" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "audit_logs_user_id_idx" ON "audit_logs"("user_id");
CREATE INDEX "audit_logs_action_idx" ON "audit_logs"("action");
CREATE INDEX "audit_logs_target_type_target_id_idx" ON "audit_logs"("target_type", "target_id");
CREATE INDEX "audit_logs_created_at_idx" ON "audit_logs"("created_at");

-- AddForeignKey
ALTER TABLE "audit_logs" ADD CONSTRAINT "audit_logs_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
