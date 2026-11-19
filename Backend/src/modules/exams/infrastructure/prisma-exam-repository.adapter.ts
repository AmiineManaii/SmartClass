import { getPrismaClient } from '../../../shared/infrastructure/prisma.js';
import type {
  ExamAnswer,
  ExamAttemptDetail,
  ExamAttemptStatus,
  ExamAttemptSummary,
  ExamDetail,
  ExamEvent,
  ExamEventState,
  ExamQuestion,
  ExamRecording,
  ExamSettings,
  ExamSource,
  ExamStatus,
  ExamSummary,
} from '../domain/exam.entity.js';
import {
  normalizeSettings,
  parseCorrectOptionIds,
  parseOptions,
  remainingMs,
} from '../domain/exam-policy.js';
import type {
  CreateAttemptInput,
  CreateEventInput,
  CreateExamInput,
  CreateFraudReportInput,
  CreateRecordingInput,
  ExamRepositoryPort,
  FinalizeAttemptInput,
  UpdateExamInput,
} from '../domain/exam-repository.port.js';

interface RawQuestionRow {
  id: string;
  examId: string;
  order: number;
  type: string;
  prompt: string;
  hint: string | null;
  options: unknown;
  correctOptionIds: unknown;
  explanation: string | null;
  points: number;
}

interface RawExamRow {
  id: string;
  title: string;
  description: string | null;
  classGroupId: string;
  authorId: string;
  durationMinutes: number;
  startsAt: Date;
  endsAt: Date;
  status: string;
  source: string;
  settings: unknown;
  publishedAt: Date | null;
  createdAt: Date;
  updatedAt: Date;
  classGroup?: { name: string } | null;
  questions?: RawQuestionRow[];
}

interface RawAnswerRow {
  questionId: string;
  selectedOptionIds: unknown;
  savedAt: Date;
}

interface RawAttemptRow {
  id: string;
  examId: string;
  studentId: string;
  status: string;
  startedAt: Date;
  expiresAt: Date;
  submittedAt: Date | null;
  score: number | null;
  maxScore: number;
  violationCount: number;
  terminatedReason: string | null;
  exam?: { title: string };
  student?: { firstName: string; lastName: string };
  answers?: RawAnswerRow[];
}

interface RawEventRow {
  id: string;
  attemptId: string;
  examId: string;
  studentId: string;
  type: string;
  severity: string;
  state: string;
  occurredAt: Date;
  durationMs: number | null;
  source: string;
  metadata: unknown;
  decision: string;
  createdAt: Date;
}

interface RawRecordingRow {
  id: string;
  attemptId: string;
  examId: string;
  studentId: string;
  eventId: string | null;
  kind: string;
  storageKey: string;
  mimeType: string;
  sizeBytes: bigint | null;
  durationMs: number | null;
  createdAt: Date;
}

const toSettings = (value: unknown): ExamSettings => normalizeSettings(value);

const toQuestion = (row: RawQuestionRow): ExamQuestion => ({
  id: row.id,
  examId: row.examId,
  order: row.order,
  type: 'SINGLE_CHOICE',
  prompt: row.prompt,
  hint: row.hint,
  options: parseOptions(row.options),
  correctOptionIds: parseCorrectOptionIds(row.correctOptionIds),
  explanation: row.explanation,
  points: row.points,
});

const toAnswer = (row: RawAnswerRow): ExamAnswer => ({
  questionId: row.questionId,
  selectedOptionIds: parseCorrectOptionIds(row.selectedOptionIds),
  savedAt: row.savedAt,
});

const studentName = (row: RawAttemptRow): string => {
  if (!row.student) return 'Étudiant';
  return `${row.student.firstName} ${row.student.lastName}`.trim();
};

const toSummary = (row: RawExamRow): ExamSummary => {
  const questions = row.questions ?? [];
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    classGroupId: row.classGroupId,
    className: row.classGroup?.name ?? null,
    authorId: row.authorId,
    durationMinutes: row.durationMinutes,
    startsAt: row.startsAt,
    endsAt: row.endsAt,
    status: row.status as ExamStatus,
    source: row.source as ExamSource,
    settings: toSettings(row.settings),
    questionCount: questions.length,
    totalPoints: questions.reduce((sum, question) => sum + question.points, 0),
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  };
};

const toDetail = (row: RawExamRow): ExamDetail => ({
  ...toSummary(row),
  questions: (row.questions ?? [])
    .slice()
    .sort((a, b) => a.order - b.order)
    .map(toQuestion),
});

const toAttemptDetail = (row: RawAttemptRow, now: Date): ExamAttemptDetail => ({
  id: row.id,
  examId: row.examId,
  examTitle: row.exam?.title ?? '',
  studentId: row.studentId,
  studentName: studentName(row),
  studentCode: null,
  status: row.status as ExamAttemptStatus,
  startedAt: row.startedAt,
  expiresAt: row.expiresAt,
  submittedAt: row.submittedAt,
  score: row.score,
  maxScore: row.maxScore,
  violationCount: row.violationCount,
  terminatedReason: row.terminatedReason,
  answers: (row.answers ?? []).map(toAnswer),
  remainingMs: remainingMs(row.expiresAt, now),
});

const toAttemptSummary = (row: RawAttemptRow, now: Date): ExamAttemptSummary => ({
  id: row.id,
  examId: row.examId,
  examTitle: row.exam?.title ?? '',
  studentId: row.studentId,
  studentName: studentName(row),
  studentCode: null,
  status: row.status as ExamAttemptStatus,
  startedAt: row.startedAt,
  expiresAt: row.expiresAt,
  submittedAt: row.submittedAt,
  score: row.score,
  maxScore: row.maxScore,
  violationCount: row.violationCount,
  terminatedReason: row.terminatedReason,
  answers: (row.answers ?? []).map(toAnswer),
  remainingMs: remainingMs(row.expiresAt, now),
});

const toEvent = (row: RawEventRow): ExamEvent => ({
  id: row.id,
  attemptId: row.attemptId,
  examId: row.examId,
  studentId: row.studentId,
  type: row.type as ExamEvent['type'],
  severity: row.severity as ExamEvent['severity'],
  state: row.state as ExamEventState,
  occurredAt: row.occurredAt,
  durationMs: row.durationMs,
  source: row.source,
  metadata:
    row.metadata && typeof row.metadata === 'object' && !Array.isArray(row.metadata)
      ? (row.metadata as Record<string, unknown>)
      : {},
  decision: row.decision,
  createdAt: row.createdAt,
});

const toRecording = (row: RawRecordingRow): ExamRecording => ({
  id: row.id,
  attemptId: row.attemptId,
  examId: row.examId,
  studentId: row.studentId,
  eventId: row.eventId,
  kind: row.kind,
  storageKey: row.storageKey,
  mimeType: row.mimeType,
  sizeBytes: row.sizeBytes === null ? null : Number(row.sizeBytes),
  durationMs: row.durationMs,
  createdAt: row.createdAt,
});

const examInclude = {
  classGroup: { select: { name: true } },
  questions: { orderBy: { order: 'asc' } },
} as const;

const attemptInclude = {
  exam: { select: { title: true } },
  student: { select: { firstName: true, lastName: true } },
  answers: true,
} as const;

export class PrismaExamRepositoryAdapter implements ExamRepositoryPort {
  private get prisma() {
    return getPrismaClient();
  }

  public async createExam(input: CreateExamInput): Promise<ExamDetail> {
    const row = (await this.prisma.exam.create({
      data: {
        title: input.title,
        description: input.description,
        classGroupId: input.classGroupId,
        authorId: input.authorId,
        durationMinutes: input.durationMinutes,
        startsAt: input.startsAt,
        endsAt: input.endsAt,
        source: input.source,
        settings: input.settings as unknown as object,
        questions: {
          create: input.questions.map((question, index) => ({
            order: index + 1,
            type: question.type ?? 'SINGLE_CHOICE',
            prompt: question.prompt,
            hint: question.hint ?? null,
            options: question.options as unknown as object,
            correctOptionIds: question.correctOptionIds as unknown as object,
            explanation: question.explanation ?? null,
            points: question.points,
          })),
        },
      },
      include: examInclude,
    })) as unknown as RawExamRow;
    return toDetail(row);
  }

  public async updateExam(examId: string, input: UpdateExamInput): Promise<ExamDetail> {
    if (input.questions) {
      await this.prisma.examQuestion.deleteMany({ where: { examId } });
    }
    const row = (await this.prisma.exam.update({
      where: { id: examId },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(input.description !== undefined ? { description: input.description } : {}),
        ...(input.durationMinutes !== undefined
          ? { durationMinutes: input.durationMinutes }
          : {}),
        ...(input.startsAt !== undefined ? { startsAt: input.startsAt } : {}),
        ...(input.endsAt !== undefined ? { endsAt: input.endsAt } : {}),
        ...(input.settings !== undefined
          ? { settings: input.settings as unknown as object }
          : {}),
        ...(input.questions
          ? {
              questions: {
                create: input.questions.map((question, index) => ({
                  order: index + 1,
                  type: question.type ?? 'SINGLE_CHOICE',
                  prompt: question.prompt,
                  hint: question.hint ?? null,
                  options: question.options as unknown as object,
                  correctOptionIds: question.correctOptionIds as unknown as object,
                  explanation: question.explanation ?? null,
                  points: question.points,
                })),
              },
            }
          : {}),
      },
      include: examInclude,
    })) as unknown as RawExamRow;
    return toDetail(row);
  }

  public async findExamById(examId: string): Promise<ExamDetail | null> {
    const row = (await this.prisma.exam.findUnique({
      where: { id: examId },
      include: examInclude,
    })) as unknown as RawExamRow | null;
    return row ? toDetail(row) : null;
  }

  public async listExamsByAuthor(authorId: string): Promise<ExamSummary[]> {
    const rows = (await this.prisma.exam.findMany({
      where: { authorId },
      orderBy: { createdAt: 'desc' },
      include: examInclude,
    })) as unknown as RawExamRow[];
    return rows.map(toSummary);
  }

  public async listPublishedExamsForClasses(classGroupIds: string[]): Promise<ExamSummary[]> {
    if (classGroupIds.length === 0) return [];
    const rows = (await this.prisma.exam.findMany({
      where: { status: 'PUBLISHED', classGroupId: { in: classGroupIds } },
      orderBy: { startsAt: 'asc' },
      include: examInclude,
    })) as unknown as RawExamRow[];
    return rows.map(toSummary);
  }

  public async setExamStatus(
    examId: string,
    status: ExamStatus,
    publishedAt: Date | null,
  ): Promise<ExamDetail> {
    const row = (await this.prisma.exam.update({
      where: { id: examId },
      data: { status, publishedAt },
      include: examInclude,
    })) as unknown as RawExamRow;
    return toDetail(row);
  }

  public async findAttemptByExamAndStudent(
    examId: string,
    studentId: string,
  ): Promise<ExamAttemptDetail | null> {
    const row = (await this.prisma.examAttempt.findUnique({
      where: { examId_studentId: { examId, studentId } },
      include: attemptInclude,
    })) as unknown as RawAttemptRow | null;
    return row ? toAttemptDetail(row, new Date()) : null;
  }

  public async findAttemptById(attemptId: string): Promise<ExamAttemptDetail | null> {
    const row = (await this.prisma.examAttempt.findUnique({
      where: { id: attemptId },
      include: attemptInclude,
    })) as unknown as RawAttemptRow | null;
    return row ? toAttemptDetail(row, new Date()) : null;
  }

  public async createAttempt(input: CreateAttemptInput): Promise<ExamAttemptDetail> {
    const row = (await this.prisma.examAttempt.create({
      data: {
        examId: input.examId,
        studentId: input.studentId,
        startedAt: input.startedAt,
        expiresAt: input.expiresAt,
        maxScore: input.maxScore,
        lastSeenAt: input.startedAt,
      },
      include: attemptInclude,
    })) as unknown as RawAttemptRow;
    return toAttemptDetail(row, input.startedAt);
  }

  public async upsertAnswer(
    attemptId: string,
    questionId: string,
    selectedOptionIds: string[],
    savedAt: Date,
  ): Promise<void> {
    await this.prisma.examAnswer.upsert({
      where: { attemptId_questionId: { attemptId, questionId } },
      create: {
        attemptId,
        questionId,
        selectedOptionIds: selectedOptionIds as unknown as object,
        savedAt,
      },
      update: {
        selectedOptionIds: selectedOptionIds as unknown as object,
        savedAt,
      },
    });
  }

  public async finalizeAttempt(
    attemptId: string,
    input: FinalizeAttemptInput,
  ): Promise<ExamAttemptDetail> {
    const row = (await this.prisma.examAttempt.update({
      where: { id: attemptId },
      data: {
        status: input.status,
        submittedAt: input.submittedAt,
        score: input.score,
        maxScore: input.maxScore,
        terminatedReason: input.terminatedReason,
      },
      include: attemptInclude,
    })) as unknown as RawAttemptRow;
    return toAttemptDetail(row, input.submittedAt);
  }

  public async touchAttempt(attemptId: string, seenAt: Date): Promise<void> {
    await this.prisma.examAttempt.update({
      where: { id: attemptId },
      data: { lastSeenAt: seenAt },
    });
  }

  public async setAttemptViolationCount(attemptId: string, count: number): Promise<void> {
    await this.prisma.examAttempt.update({
      where: { id: attemptId },
      data: { violationCount: count },
    });
  }

  public async listAttemptsByExam(examId: string): Promise<ExamAttemptSummary[]> {
    const now = new Date();
    const rows = (await this.prisma.examAttempt.findMany({
      where: { examId },
      orderBy: { startedAt: 'asc' },
      include: attemptInclude,
    })) as unknown as RawAttemptRow[];
    return rows.map((row) => toAttemptSummary(row, now));
  }

  public async listAttemptsByStudent(studentId: string): Promise<ExamAttemptSummary[]> {
    const now = new Date();
    const rows = (await this.prisma.examAttempt.findMany({
      where: { studentId },
      orderBy: { startedAt: 'desc' },
      include: attemptInclude,
    })) as unknown as RawAttemptRow[];
    return rows.map((row) => toAttemptSummary(row, now));
  }

  public async createEvent(input: CreateEventInput): Promise<ExamEvent> {
    const row = (await this.prisma.examEvent.create({
      data: {
        attemptId: input.attemptId,
        examId: input.examId,
        studentId: input.studentId,
        type: input.type,
        severity: input.severity,
        occurredAt: input.occurredAt,
        durationMs: input.durationMs,
        source: input.source,
        metadata: input.metadata as unknown as object,
        decision: input.decision,
      },
    })) as unknown as RawEventRow;
    return toEvent(row);
  }

  public async findEventById(eventId: string): Promise<ExamEvent | null> {
    const row = (await this.prisma.examEvent.findUnique({
      where: { id: eventId },
    })) as unknown as RawEventRow | null;
    return row ? toEvent(row) : null;
  }

  public async listEventsByAttempt(attemptId: string): Promise<ExamEvent[]> {
    const rows = (await this.prisma.examEvent.findMany({
      where: { attemptId },
      orderBy: { occurredAt: 'asc' },
    })) as unknown as RawEventRow[];
    return rows.map(toEvent);
  }

  public async updateEventState(eventId: string, state: ExamEventState): Promise<ExamEvent> {
    const row = (await this.prisma.examEvent.update({
      where: { id: eventId },
      data: { state },
    })) as unknown as RawEventRow;
    return toEvent(row);
  }

  public async createRecording(input: CreateRecordingInput): Promise<ExamRecording> {
    const row = (await this.prisma.examRecording.create({
      data: {
        attemptId: input.attemptId,
        examId: input.examId,
        studentId: input.studentId,
        eventId: input.eventId,
        kind: input.kind,
        storageKey: input.storageKey,
        mimeType: input.mimeType,
        sizeBytes: input.sizeBytes === null ? null : BigInt(input.sizeBytes),
        durationMs: input.durationMs,
      },
    })) as unknown as RawRecordingRow;
    return toRecording(row);
  }

  public async findRecordingById(recordingId: string): Promise<ExamRecording | null> {
    const row = (await this.prisma.examRecording.findUnique({
      where: { id: recordingId },
    })) as unknown as RawRecordingRow | null;
    return row ? toRecording(row) : null;
  }

  public async listRecordingsByAttempt(attemptId: string): Promise<ExamRecording[]> {
    const rows = (await this.prisma.examRecording.findMany({
      where: { attemptId },
      orderBy: { createdAt: 'asc' },
    })) as unknown as RawRecordingRow[];
    return rows.map(toRecording);
  }

  public async listRecordingsByExam(examId: string): Promise<ExamRecording[]> {
    const rows = (await this.prisma.examRecording.findMany({
      where: { examId },
      orderBy: { createdAt: 'asc' },
    })) as unknown as RawRecordingRow[];
    return rows.map(toRecording);
  }

  public async deleteRecording(recordingId: string): Promise<void> {
    await this.prisma.examRecording.delete({ where: { id: recordingId } });
  }

  public async createFraudReport(input: CreateFraudReportInput): Promise<void> {
    await this.prisma.fraudReport.create({
      data: {
        title: input.title,
        context: input.context,
        severity: input.severity,
        status: 'UNTREATED',
        studentId: input.studentId,
        studentName: input.studentName,
        studentCode: input.studentCode,
        classGroupId: input.classGroupId,
        className: input.className,
        findings: input.findings as unknown as object,
        reason: input.reason,
        occurredAt: input.occurredAt,
      },
    });
  }

  public async findClassGroup(
    classGroupId: string,
  ): Promise<{ id: string; name: string } | null> {
    const row = await this.prisma.classGroup.findUnique({
      where: { id: classGroupId },
      select: { id: true, name: true },
    });
    return row ?? null;
  }

  public async isTeacherOfClass(teacherId: string, classGroupId: string): Promise<boolean> {
    const row = await this.prisma.classGroup.findFirst({
      where: {
        id: classGroupId,
        OR: [
          { ownerId: teacherId },
          { referentId: teacherId },
          { teachers: { some: { teacherId } } },
        ],
      },
      select: { id: true },
    });
    return row !== null;
  }

  public async isStudentOfClass(studentId: string, classGroupId: string): Promise<boolean> {
    const row = await this.prisma.groupMember.findFirst({
      where: { userId: studentId, classGroupId },
      select: { id: true },
    });
    return row !== null;
  }

  public async listStudentClassIds(studentId: string): Promise<string[]> {
    const rows = await this.prisma.groupMember.findMany({
      where: { userId: studentId },
      select: { classGroupId: true },
    });
    return rows.map((row) => row.classGroupId);
  }

  public async listClassCourses(
    classGroupId: string,
    authorId?: string,
  ): Promise<{ id: string; title: string; subject: string | null; content: string }[]> {
    const rows = await this.prisma.course.findMany({
      where: authorId
        ? {
            // Publication is the validation gate: sections must be VALIDATED
            // before a course can reach PUBLISHED.
            status: 'PUBLISHED',
            OR: [
              { classGroups: { some: { classGroupId } } },
              // The courses UI does not assign a class yet: a published
              // course left unrestricted belongs to its author and is
              // readable by everyone, so it remains a valid source for the
              // author's own classes.
              { authorId, classGroups: { none: {} } },
            ],
          }
        : {
            status: 'PUBLISHED',
            classGroups: { some: { classGroupId } },
          },
      orderBy: { createdAt: 'desc' },
      select: { id: true, title: true, subject: true, content: true },
    });
    return rows;
  }
}
