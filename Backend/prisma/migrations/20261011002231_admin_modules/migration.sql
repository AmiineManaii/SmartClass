-- CreateEnum
CREATE TYPE "ClassLevel" AS ENUM ('LICENCE', 'MASTER', 'DOCTORAT');

-- CreateEnum
CREATE TYPE "ClassStatus" AS ENUM ('DRAFT', 'PUBLISHED');

-- CreateEnum
CREATE TYPE "TimetableKind" AS ENUM ('CM', 'TP', 'TD', 'BREAK', 'LUNCH', 'FREE');

-- CreateEnum
CREATE TYPE "FraudSeverity" AS ENUM ('LOW', 'MEDIUM', 'HIGH');

-- CreateEnum
CREATE TYPE "FraudStatus" AS ENUM ('UNTREATED', 'IN_PROGRESS', 'CLOSED');

-- CreateTable
CREATE TABLE "class_groups" (
    "id" UUID NOT NULL,
    "name" TEXT NOT NULL,
    "level" "ClassLevel" NOT NULL,
    "department" TEXT,
    "capacity" INTEGER NOT NULL,
    "description" TEXT,
    "forum_enabled" BOOLEAN NOT NULL DEFAULT true,
    "ent_sync_enabled" BOOLEAN NOT NULL DEFAULT true,
    "status" "ClassStatus" NOT NULL DEFAULT 'PUBLISHED',
    "referent_id" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "class_groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "group_members" (
    "id" UUID NOT NULL,
    "class_group_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "joined_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "group_members_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "teacher_assignments" (
    "id" UUID NOT NULL,
    "class_group_id" UUID NOT NULL,
    "teacher_id" UUID NOT NULL,
    "subject" TEXT NOT NULL,
    "weekly_hours" TEXT,
    "assigned_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "teacher_assignments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "timetable_slots" (
    "id" UUID NOT NULL,
    "class_group_id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "subtitle" TEXT,
    "kind" "TimetableKind" NOT NULL,
    "starts_at" TIMESTAMPTZ NOT NULL,
    "ends_at" TIMESTAMPTZ NOT NULL,
    "teacher_id" UUID,
    "room" TEXT,
    "status_notes" JSONB NOT NULL DEFAULT '[]',
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "timetable_slots_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "fraud_reports" (
    "id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "context" TEXT,
    "severity" "FraudSeverity" NOT NULL,
    "status" "FraudStatus" NOT NULL DEFAULT 'UNTREATED',
    "student_id" UUID,
    "student_name" TEXT NOT NULL,
    "student_code" TEXT,
    "class_group_id" UUID,
    "class_name" TEXT,
    "findings" JSONB NOT NULL DEFAULT '[]',
    "reason" TEXT,
    "resolution" TEXT,
    "occurred_at" TIMESTAMPTZ NOT NULL,
    "closed_at" TIMESTAMPTZ,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "fraud_reports_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "class_groups_level_idx" ON "class_groups"("level");

-- CreateIndex
CREATE INDEX "class_groups_status_idx" ON "class_groups"("status");

-- CreateIndex
CREATE INDEX "class_groups_referent_id_idx" ON "class_groups"("referent_id");

-- CreateIndex
CREATE INDEX "group_members_class_group_id_idx" ON "group_members"("class_group_id");

-- CreateIndex
CREATE INDEX "group_members_user_id_idx" ON "group_members"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "group_members_class_group_id_user_id_key" ON "group_members"("class_group_id", "user_id");

-- CreateIndex
CREATE INDEX "teacher_assignments_class_group_id_idx" ON "teacher_assignments"("class_group_id");

-- CreateIndex
CREATE INDEX "teacher_assignments_teacher_id_idx" ON "teacher_assignments"("teacher_id");

-- CreateIndex
CREATE UNIQUE INDEX "teacher_assignments_class_group_id_teacher_id_key" ON "teacher_assignments"("class_group_id", "teacher_id");

-- CreateIndex
CREATE INDEX "timetable_slots_class_group_id_idx" ON "timetable_slots"("class_group_id");

-- CreateIndex
CREATE INDEX "timetable_slots_starts_at_idx" ON "timetable_slots"("starts_at");

-- CreateIndex
CREATE INDEX "fraud_reports_status_idx" ON "fraud_reports"("status");

-- CreateIndex
CREATE INDEX "fraud_reports_severity_idx" ON "fraud_reports"("severity");

-- CreateIndex
CREATE INDEX "fraud_reports_student_id_idx" ON "fraud_reports"("student_id");

-- CreateIndex
CREATE INDEX "fraud_reports_occurred_at_idx" ON "fraud_reports"("occurred_at");

-- AddForeignKey
ALTER TABLE "class_groups" ADD CONSTRAINT "class_groups_referent_id_fkey" FOREIGN KEY ("referent_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_members" ADD CONSTRAINT "group_members_class_group_id_fkey" FOREIGN KEY ("class_group_id") REFERENCES "class_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_members" ADD CONSTRAINT "group_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "teacher_assignments" ADD CONSTRAINT "teacher_assignments_class_group_id_fkey" FOREIGN KEY ("class_group_id") REFERENCES "class_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "teacher_assignments" ADD CONSTRAINT "teacher_assignments_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "timetable_slots" ADD CONSTRAINT "timetable_slots_class_group_id_fkey" FOREIGN KEY ("class_group_id") REFERENCES "class_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "timetable_slots" ADD CONSTRAINT "timetable_slots_teacher_id_fkey" FOREIGN KEY ("teacher_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fraud_reports" ADD CONSTRAINT "fraud_reports_student_id_fkey" FOREIGN KEY ("student_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "fraud_reports" ADD CONSTRAINT "fraud_reports_class_group_id_fkey" FOREIGN KEY ("class_group_id") REFERENCES "class_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;
