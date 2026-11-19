import type {
  ExamAnswer,
  ExamAttemptDetail,
  ExamAttemptStatus,
  ExamAttemptSummary,
  ExamDetail,
  ExamEvent,
  ExamEventState,
  ExamEventType,
  ExamRecording,
  ExamSettings,
  ExamSeverity,
  ExamSource,
  ExamStatus,
  ExamSummary,
} from '../../src/modules/exams/domain/exam.entity.js';
import { DEFAULT_EXAM_SETTINGS, remainingMs } from '../../src/modules/exams/domain/exam-policy.js';
import type {
  CreateAttemptInput,
  CreateEventInput,
  CreateExamInput,
  CreateFraudReportInput,
  CreateRecordingInput,
  ExamRepositoryPort,
  FinalizeAttemptInput,
  UpdateExamInput,
} from '../../src/modules/exams/domain/exam-repository.port.js';

let seq = 0;

const nextId = (prefix: string): string => {
  seq += 1;
  return `${prefix}-${seq}`;
};

export class FakeExamRepository implements ExamRepositoryPort {
  public readonly exams = new Map<string, ExamDetail>();
  public readonly attempts = new Map<string, ExamAttemptDetail>();
  public readonly events: ExamEvent[] = [];
  public readonly recordings: ExamRecording[] = [];
  public readonly classes = new Map<string, string>();
  public readonly teacherClasses = new Set<string>();
  public readonly studentClasses = new Map<string, string[]>();
  public readonly classCourses = new Map<
    string,
    { id: string; title: string; subject: string | null; content: string }[]
  >();

  public allowTeacher(teacherId: string, classGroupId: string): void {
    this.teacherClasses.add(`${teacherId}:${classGroupId}`);
  }

  public enroll(studentId: string, classGroupId: string): void {
    const current = this.studentClasses.get(studentId) ?? [];
    this.studentClasses.set(studentId, [...current, classGroupId]);
  }

  public addClass(id: string, name: string): void {
    this.classes.set(id, name);
  }

  public seedExam(
    overrides: Partial<ExamDetail> & { classGroupId: string; authorId: string },
  ): ExamDetail {
    const id = overrides.id ?? nextId('exam');
    const questions = (overrides.questions ?? []).map((question, index) => ({
      ...question,
      examId: id,
      order: index + 1,
    }));
    const now = new Date();
    const exam: ExamDetail = {
      id,
      title: overrides.title ?? 'Examen',
      description: overrides.description ?? null,
      classGroupId: overrides.classGroupId,
      className: this.classes.get(overrides.classGroupId) ?? 'Classe',
      authorId: overrides.authorId,
      durationMinutes: overrides.durationMinutes ?? 30,
      startsAt: overrides.startsAt ?? new Date(now.getTime() - 60_000),
      endsAt: overrides.endsAt ?? new Date(now.getTime() + 3_600_000),
      status: overrides.status ?? 'PUBLISHED',
      source: overrides.source ?? 'MANUAL',
      settings: { ...DEFAULT_EXAM_SETTINGS, ...(overrides.settings ?? {}) },
      questionCount: questions.length,
      totalPoints: questions.reduce((sum, question) => sum + question.points, 0),
      createdAt: now,
      updatedAt: now,
      questions,
    };
    this.exams.set(id, exam);
    return exam;
  }

  public async createExam(input: CreateExamInput): Promise<ExamDetail> {
    const id = nextId('exam');
    const now = new Date();
    const questions = input.questions.map((question, index) => ({
      id: nextId('q'),
      examId: id,
      order: index + 1,
      type: question.type ?? ('SINGLE_CHOICE' as const),
      prompt: question.prompt,
      hint: question.hint ?? null,
      options: question.options,
      correctOptionIds: question.correctOptionIds,
      explanation: question.explanation ?? null,
      points: question.points,
    }));
    const exam: ExamDetail = {
      id,
      title: input.title,
      description: input.description,
      classGroupId: input.classGroupId,
      className: this.classes.get(input.classGroupId) ?? 'Classe',
      authorId: input.authorId,
      durationMinutes: input.durationMinutes,
      startsAt: input.startsAt,
      endsAt: input.endsAt,
      status: 'DRAFT',
      source: input.source,
      settings: input.settings,
      questionCount: questions.length,
      totalPoints: questions.reduce((sum, question) => sum + question.points, 0),
      createdAt: now,
      updatedAt: now,
      questions,
    };
    this.exams.set(id, exam);
    return exam;
  }

  public async updateExam(examId: string, input: UpdateExamInput): Promise<ExamDetail> {
    const existing = this.exams.get(examId);
    if (!existing) throw new Error('exam missing');
    const questions = input.questions
      ? input.questions.map((question, index) => ({
          id: nextId('q'),
          examId,
          order: index + 1,
          type: question.type ?? ('SINGLE_CHOICE' as const),
          prompt: question.prompt,
          hint: question.hint ?? null,
          options: question.options,
          correctOptionIds: question.correctOptionIds,
          explanation: question.explanation ?? null,
          points: question.points,
        }))
      : existing.questions;
    const next: ExamDetail = {
      ...existing,
      ...(input.title !== undefined ? { title: input.title } : {}),
      ...(input.description !== undefined ? { description: input.description } : {}),
      ...(input.durationMinutes !== undefined ? { durationMinutes: input.durationMinutes } : {}),
      ...(input.startsAt !== undefined ? { startsAt: input.startsAt } : {}),
      ...(input.endsAt !== undefined ? { endsAt: input.endsAt } : {}),
      ...(input.settings !== undefined ? { settings: input.settings } : {}),
      questions,
      questionCount: questions.length,
      totalPoints: questions.reduce((sum, question) => sum + question.points, 0),
      updatedAt: new Date(),
    };
    this.exams.set(examId, next);
    return next;
  }

  public async findExamById(examId: string): Promise<ExamDetail | null> {
    return this.exams.get(examId) ?? null;
  }

  public async listExamsByAuthor(authorId: string): Promise<ExamSummary[]> {
    return [...this.exams.values()].filter((exam) => exam.authorId === authorId);
  }

  public async listPublishedExamsForClasses(classGroupIds: string[]): Promise<ExamSummary[]> {
    return [...this.exams.values()].filter(
      (exam) => exam.status === 'PUBLISHED' && classGroupIds.includes(exam.classGroupId),
    );
  }

  public async setExamStatus(
    examId: string,
    status: ExamStatus,
    publishedAt: Date | null,
  ): Promise<ExamDetail> {
    const exam = this.exams.get(examId);
    if (!exam) throw new Error('exam missing');
    const next = { ...exam, status, publishedAt, updatedAt: new Date() } as ExamDetail & {
      publishedAt: Date | null;
    };
    this.exams.set(examId, next);
    return next;
  }

  private cloneAttempt(attempt: ExamAttemptDetail, now = new Date()): ExamAttemptDetail {
    return {
      ...attempt,
      answers: attempt.answers.map((answer) => ({ ...answer })),
      remainingMs: remainingMs(attempt.expiresAt, now),
    };
  }

  public async findAttemptByExamAndStudent(
    examId: string,
    studentId: string,
  ): Promise<ExamAttemptDetail | null> {
    const attempt = [...this.attempts.values()].find(
      (entry) => entry.examId === examId && entry.studentId === studentId,
    );
    return attempt ? this.cloneAttempt(attempt) : null;
  }

  public async findAttemptById(attemptId: string): Promise<ExamAttemptDetail | null> {
    const attempt = this.attempts.get(attemptId);
    return attempt ? this.cloneAttempt(attempt) : null;
  }

  public async createAttempt(input: CreateAttemptInput): Promise<ExamAttemptDetail> {
    const exam = this.exams.get(input.examId);
    if (!exam) throw new Error('exam missing');
    const attempt: ExamAttemptDetail = {
      id: nextId('attempt'),
      examId: input.examId,
      examTitle: exam.title,
      studentId: input.studentId,
      studentName: `Student ${input.studentId}`,
      studentCode: null,
      status: 'IN_PROGRESS',
      startedAt: input.startedAt,
      expiresAt: input.expiresAt,
      submittedAt: null,
      score: null,
      maxScore: input.maxScore,
      violationCount: 0,
      terminatedReason: null,
      answers: [],
      remainingMs: remainingMs(input.expiresAt, input.startedAt),
    };
    this.attempts.set(attempt.id, attempt);
    return this.cloneAttempt(attempt, input.startedAt);
  }

  public async upsertAnswer(
    attemptId: string,
    questionId: string,
    selectedOptionIds: string[],
    savedAt: Date,
  ): Promise<void> {
    const attempt = this.attempts.get(attemptId);
    if (!attempt) throw new Error('attempt missing');
    const existing = attempt.answers.find((answer) => answer.questionId === questionId);
    if (existing) {
      existing.selectedOptionIds = selectedOptionIds;
      existing.savedAt = savedAt;
    } else {
      attempt.answers.push({ questionId, selectedOptionIds, savedAt });
    }
  }

  public async finalizeAttempt(
    attemptId: string,
    input: FinalizeAttemptInput,
  ): Promise<ExamAttemptDetail> {
    const attempt = this.attempts.get(attemptId);
    if (!attempt) throw new Error('attempt missing');
    const next: ExamAttemptDetail = {
      ...attempt,
      status: input.status,
      submittedAt: input.submittedAt,
      score: input.score,
      maxScore: input.maxScore,
      terminatedReason: input.terminatedReason,
    };
    this.attempts.set(attemptId, next);
    return this.cloneAttempt(next, input.submittedAt);
  }

  public async touchAttempt(attemptId: string, seenAt: Date): Promise<void> {
    void attemptId;
    void seenAt;
  }

  public async setAttemptViolationCount(attemptId: string, count: number): Promise<void> {
    const attempt = this.attempts.get(attemptId);
    if (attempt) attempt.violationCount = count;
  }

  public async listAttemptsByExam(examId: string): Promise<ExamAttemptSummary[]> {
    return [...this.attempts.values()]
      .filter((attempt) => attempt.examId === examId)
      .map((attempt) => this.cloneAttempt(attempt));
  }

  public async listAttemptsByStudent(studentId: string): Promise<ExamAttemptSummary[]> {
    return [...this.attempts.values()]
      .filter((attempt) => attempt.studentId === studentId)
      .map((attempt) => this.cloneAttempt(attempt));
  }

  public async createEvent(input: CreateEventInput): Promise<ExamEvent> {
    const now = new Date();
    const event: ExamEvent = {
      id: nextId('event'),
      attemptId: input.attemptId,
      examId: input.examId,
      studentId: input.studentId,
      type: input.type as ExamEventType,
      severity: input.severity as ExamSeverity,
      state: 'NEW',
      occurredAt: input.occurredAt,
      durationMs: input.durationMs,
      source: input.source,
      metadata: input.metadata,
      decision: input.decision,
      createdAt: now,
    };
    this.events.push(event);
    return event;
  }

  public async findEventById(eventId: string): Promise<ExamEvent | null> {
    return this.events.find((event) => event.id === eventId) ?? null;
  }

  public async listEventsByAttempt(attemptId: string): Promise<ExamEvent[]> {
    return this.events.filter((event) => event.attemptId === attemptId);
  }

  public async updateEventState(eventId: string, state: ExamEventState): Promise<ExamEvent> {
    const event = this.events.find((entry) => entry.id === eventId);
    if (!event) throw new Error('event missing');
    event.state = state;
    return event;
  }

  public async createRecording(input: CreateRecordingInput): Promise<ExamRecording> {
    const recording: ExamRecording = {
      id: nextId('recording'),
      ...input,
      createdAt: new Date(),
    };
    this.recordings.push(recording);
    return recording;
  }

  public async findRecordingById(recordingId: string): Promise<ExamRecording | null> {
    return this.recordings.find((recording) => recording.id === recordingId) ?? null;
  }

  public async listRecordingsByAttempt(attemptId: string): Promise<ExamRecording[]> {
    return this.recordings.filter((recording) => recording.attemptId === attemptId);
  }

  public async listRecordingsByExam(examId: string): Promise<ExamRecording[]> {
    return this.recordings.filter((recording) => recording.examId === examId);
  }

  public async deleteRecording(recordingId: string): Promise<void> {
    const index = this.recordings.findIndex((recording) => recording.id === recordingId);
    if (index >= 0) this.recordings.splice(index, 1);
  }

  public async createFraudReport(_input: CreateFraudReportInput): Promise<void> {
    void _input;
  }

  public async findClassGroup(classGroupId: string): Promise<{ id: string; name: string } | null> {
    const name = this.classes.get(classGroupId);
    return name ? { id: classGroupId, name } : null;
  }

  public async isTeacherOfClass(teacherId: string, classGroupId: string): Promise<boolean> {
    return this.teacherClasses.has(`${teacherId}:${classGroupId}`);
  }

  public async isStudentOfClass(studentId: string, classGroupId: string): Promise<boolean> {
    return (this.studentClasses.get(studentId) ?? []).includes(classGroupId);
  }

  public async listStudentClassIds(studentId: string): Promise<string[]> {
    return this.studentClasses.get(studentId) ?? [];
  }

  public async listClassCourses(
    classGroupId: string,
    _authorId?: string,
  ): Promise<{ id: string; title: string; subject: string | null; content: string }[]> {
    return this.classCourses.get(classGroupId) ?? [];
  }
}

export const makeQuestion = (
  id: string,
  correctOptionIds: string[],
  points = 2,
): ExamDetail['questions'][number] => ({
  id,
  examId: 'seeded',
  order: 0,
  type: 'SINGLE_CHOICE',
  prompt: `Question ${id}`,
  hint: null,
  options: [
    { id: 'A', text: 'Option A' },
    { id: 'B', text: 'Option B' },
    { id: 'C', text: 'Option C' },
  ],
  correctOptionIds,
  explanation: 'Because the course says so',
  points,
});

export const examSettings = (overrides: Partial<ExamSettings> = {}): ExamSettings => ({
  ...DEFAULT_EXAM_SETTINGS,
  ...overrides,
});

export type { ExamAnswer, ExamAttemptStatus, ExamSource };
