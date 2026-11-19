/** Exam lifecycle (RG4: the AI never publishes; only the teacher does). */
export type ExamStatus = 'DRAFT' | 'PUBLISHED' | 'CLOSED';

export type ExamSource = 'MANUAL' | 'IMPORT' | 'AI';

export type ExamQuestionType = 'SINGLE_CHOICE';

export type ExamAttemptStatus = 'IN_PROGRESS' | 'SUBMITTED' | 'AUTO_SUBMITTED' | 'TERMINATED';

export type ExamSeverity = 'LOW' | 'MEDIUM' | 'HIGH';

export type ExamEventState = 'NEW' | 'REVIEWED' | 'CONFIRMED';

export type ExamEventType =
  | 'TAB_HIDDEN'
  | 'FOCUS_LOST'
  | 'PAGE_LEAVE'
  | 'PAGE_REFRESH'
  | 'FULLSCREEN_EXIT'
  | 'APP_BACKGROUND'
  | 'COPY_ATTEMPT'
  | 'PASTE_ATTEMPT'
  | 'CUT_ATTEMPT'
  | 'CONTEXT_MENU'
  | 'SCREENSHOT_ATTEMPT'
  | 'NETWORK_LOST'
  | 'NETWORK_RESTORED'
  | 'CAMERA_DENIED'
  | 'GAZE_OFF_SCREEN'
  | 'TECHNICAL_INTERRUPTION';

/** One answer proposal. The id (`A`, `B`, …) is what the client submits. */
export interface ExamOption {
  id: string;
  text: string;
}

export interface ExamQuestion {
  id: string;
  examId: string;
  order: number;
  type: ExamQuestionType;
  prompt: string;
  hint: string | null;
  options: ExamOption[];
  /** NEVER serialized in a student projection. */
  correctOptionIds: string[];
  explanation: string | null;
  points: number;
}

/** Question shape returned to students: no correct answers, no explanation. */
export interface StudentExamQuestion {
  id: string;
  order: number;
  type: ExamQuestionType;
  prompt: string;
  hint: string | null;
  options: ExamOption[];
  points: number;
}

export interface ExamSettings {
  shuffleQuestions: boolean;
  requireCamera: boolean;
  allowQuestionSkip: boolean;
  showResultsAfterClose: boolean;
  /**
   * Number of confirmed violations tolerated before automatic termination
   * (copy/paste family). Defaults to 3. High-severity exits terminate on
   * the first confirmed occurrence regardless of this counter.
   */
  maxViolationCount: number;
}

export const DEFAULT_EXAM_SETTINGS: ExamSettings = {
  shuffleQuestions: false,
  requireCamera: false,
  allowQuestionSkip: true,
  showResultsAfterClose: true,
  maxViolationCount: 3,
};

export interface ExamSummary {
  id: string;
  title: string;
  description: string | null;
  classGroupId: string;
  className: string | null;
  authorId: string;
  durationMinutes: number;
  startsAt: Date;
  endsAt: Date;
  status: ExamStatus;
  source: ExamSource;
  settings: ExamSettings;
  questionCount: number;
  totalPoints: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface ExamDetail extends ExamSummary {
  /** Teacher-only: correct answers included. */
  questions: ExamQuestion[];
}

export interface ExamAnswer {
  questionId: string;
  selectedOptionIds: string[];
  savedAt: Date;
}

export interface ExamAttemptSummary {
  id: string;
  examId: string;
  examTitle: string;
  studentId: string;
  studentName: string;
  studentCode: string | null;
  status: ExamAttemptStatus;
  startedAt: Date;
  expiresAt: Date;
  submittedAt: Date | null;
  score: number | null;
  maxScore: number;
  violationCount: number;
  terminatedReason: string | null;
  /** Milliseconds left according to the server clock (0 once expired). */
  remainingMs: number;
  /** Loaded by teacher result views to compute the correct-answer count. */
  answers?: ExamAnswer[];
}

export interface ExamAttemptDetail extends ExamAttemptSummary {
  answers: ExamAnswer[];
  /** Milliseconds left according to the server clock (0 once expired). */
  remainingMs: number;
}

export interface ExamEvent {
  id: string;
  attemptId: string;
  examId: string;
  studentId: string;
  type: ExamEventType;
  severity: ExamSeverity;
  state: ExamEventState;
  occurredAt: Date;
  durationMs: number | null;
  source: string;
  metadata: Record<string, unknown>;
  decision: string;
  createdAt: Date;
}

export interface ExamRecording {
  id: string;
  attemptId: string;
  examId: string;
  studentId: string;
  eventId: string | null;
  kind: string;
  storageKey: string;
  mimeType: string;
  sizeBytes: number | null;
  durationMs: number | null;
  createdAt: Date;
}

export interface ExamResultEntry {
  attemptId: string;
  studentId: string;
  studentName: string;
  status: ExamAttemptStatus;
  score: number | null;
  maxScore: number;
  correctCount: number;
  questionCount: number;
  submittedAt: Date | null;
  violationCount: number;
}

export interface ExamResults {
  examId: string;
  examTitle: string;
  status: ExamStatus;
  attemptCount: number;
  averageScore: number | null;
  results: ExamResultEntry[];
}
