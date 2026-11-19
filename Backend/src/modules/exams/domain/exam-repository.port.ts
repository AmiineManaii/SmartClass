import type {
  ExamAttemptDetail,
  ExamAttemptStatus,
  ExamAttemptSummary,
  ExamDetail,
  ExamEvent,
  ExamEventState,
  ExamEventType,
  ExamQuestionType,
  ExamRecording,
  ExamSeverity,
  ExamSettings,
  ExamSource,
  ExamStatus,
  ExamSummary,
} from './exam.entity.js';

export interface CreateExamQuestionInput {
  prompt: string;
  hint?: string | null;
  options: { id: string; text: string }[];
  correctOptionIds: string[];
  explanation?: string | null;
  points: number;
  type?: ExamQuestionType;
}

export interface CreateExamInput {
  title: string;
  description: string | null;
  classGroupId: string;
  authorId: string;
  durationMinutes: number;
  startsAt: Date;
  endsAt: Date;
  source: ExamSource;
  settings: ExamSettings;
  questions: CreateExamQuestionInput[];
}

export interface UpdateExamInput {
  title?: string;
  description?: string | null;
  durationMinutes?: number;
  startsAt?: Date;
  endsAt?: Date;
  settings?: ExamSettings;
  questions?: CreateExamQuestionInput[];
}

export interface CreateAttemptInput {
  examId: string;
  studentId: string;
  startedAt: Date;
  expiresAt: Date;
  maxScore: number;
}

export interface FinalizeAttemptInput {
  status: Extract<ExamAttemptStatus, 'SUBMITTED' | 'AUTO_SUBMITTED' | 'TERMINATED'>;
  submittedAt: Date;
  score: number | null;
  maxScore: number;
  terminatedReason: string | null;
}

export interface CreateEventInput {
  attemptId: string;
  examId: string;
  studentId: string;
  type: ExamEventType;
  severity: ExamSeverity;
  occurredAt: Date;
  durationMs: number | null;
  source: string;
  metadata: Record<string, unknown>;
  decision: string;
}

export interface CreateRecordingInput {
  attemptId: string;
  examId: string;
  studentId: string;
  eventId: string | null;
  kind: string;
  storageKey: string;
  mimeType: string;
  sizeBytes: number | null;
  durationMs: number | null;
}

export interface CreateFraudReportInput {
  title: string;
  context: string | null;
  severity: ExamSeverity;
  studentId: string;
  studentName: string;
  studentCode: string | null;
  classGroupId: string;
  className: string | null;
  findings: string[];
  reason: string;
  occurredAt: Date;
}

export interface ExamRepositoryPort {
  createExam(input: CreateExamInput): Promise<ExamDetail>;
  updateExam(examId: string, input: UpdateExamInput): Promise<ExamDetail>;
  findExamById(examId: string): Promise<ExamDetail | null>;
  listExamsByAuthor(authorId: string): Promise<ExamSummary[]>;
  listPublishedExamsForClasses(classGroupIds: string[]): Promise<ExamSummary[]>;
  setExamStatus(examId: string, status: ExamStatus, publishedAt: Date | null): Promise<ExamDetail>;

  findAttemptByExamAndStudent(examId: string, studentId: string): Promise<ExamAttemptDetail | null>;
  findAttemptById(attemptId: string): Promise<ExamAttemptDetail | null>;
  createAttempt(input: CreateAttemptInput): Promise<ExamAttemptDetail>;
  upsertAnswer(
    attemptId: string,
    questionId: string,
    selectedOptionIds: string[],
    savedAt: Date,
  ): Promise<void>;
  finalizeAttempt(attemptId: string, input: FinalizeAttemptInput): Promise<ExamAttemptDetail>;
  touchAttempt(attemptId: string, seenAt: Date): Promise<void>;
  setAttemptViolationCount(attemptId: string, count: number): Promise<void>;
  listAttemptsByExam(examId: string): Promise<ExamAttemptSummary[]>;
  listAttemptsByStudent(studentId: string): Promise<ExamAttemptSummary[]>;

  createEvent(input: CreateEventInput): Promise<ExamEvent>;
  findEventById(eventId: string): Promise<ExamEvent | null>;
  listEventsByAttempt(attemptId: string): Promise<ExamEvent[]>;
  updateEventState(eventId: string, state: ExamEventState): Promise<ExamEvent>;

  createRecording(input: CreateRecordingInput): Promise<ExamRecording>;
  findRecordingById(recordingId: string): Promise<ExamRecording | null>;
  listRecordingsByAttempt(attemptId: string): Promise<ExamRecording[]>;
  listRecordingsByExam(examId: string): Promise<ExamRecording[]>;
  deleteRecording(recordingId: string): Promise<void>;

  createFraudReport(input: CreateFraudReportInput): Promise<void>;

  findClassGroup(classGroupId: string): Promise<{ id: string; name: string } | null>;
  isTeacherOfClass(teacherId: string, classGroupId: string): Promise<boolean>;
  isStudentOfClass(studentId: string, classGroupId: string): Promise<boolean>;
  listStudentClassIds(studentId: string): Promise<string[]>;
  /**
   * Published (therefore teacher-validated) courses usable for one class:
   * courses linked to the class, plus the caller's own published courses that
   * are not assigned to any class yet (unrestricted legacy courses).
   */
  listClassCourses(
    classGroupId: string,
    authorId?: string,
  ): Promise<{ id: string; title: string; subject: string | null; content: string }[]>;
}
