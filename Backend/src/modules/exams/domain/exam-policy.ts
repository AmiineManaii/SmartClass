import {
  DEFAULT_EXAM_SETTINGS,
  type ExamAnswer,
  type ExamEventType,
  type ExamOption,
  type ExamQuestion,
  type ExamSettings,
  type ExamSeverity,
  type ExamStatus,
} from './exam.entity.js';

/** Exit signals confirmed on the device (tab/app left the exam environment). */
export const CONFIRMED_EXIT_EVENT_TYPES: readonly ExamEventType[] = [
  'TAB_HIDDEN',
  'PAGE_LEAVE',
  'APP_BACKGROUND',
  'FULLSCREEN_EXIT',
];

/** A blur shorter than this is treated as a transient focus glitch. */
export const MIN_CONFIRMED_EXIT_MS = 1500;

/** Events that must never trigger a sanction (technical / independent). */
export const TECHNICAL_EVENT_TYPES: readonly ExamEventType[] = [
  'NETWORK_LOST',
  'NETWORK_RESTORED',
  'CAMERA_DENIED',
  'TECHNICAL_INTERRUPTION',
];

const COPY_PASTE_EVENT_TYPES: readonly ExamEventType[] = [
  'COPY_ATTEMPT',
  'PASTE_ATTEMPT',
  'CUT_ATTEMPT',
];

/**
 * Only repeated copy/paste/screenshot signals consume the violation budget.
 * A transient focus loss or a short tab switch must not silently push a
 * student toward termination.
 */
export const countsAsViolation = (type: ExamEventType): boolean =>
  COPY_PASTE_EVENT_TYPES.includes(type) || type === 'SCREENSHOT_ATTEMPT';

export const normalizeSettings = (raw: unknown): ExamSettings => {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) {
    return { ...DEFAULT_EXAM_SETTINGS };
  }
  const value = raw as Record<string, unknown>;
  return {
    shuffleQuestions:
      typeof value.shuffleQuestions === 'boolean'
        ? value.shuffleQuestions
        : DEFAULT_EXAM_SETTINGS.shuffleQuestions,
    requireCamera:
      typeof value.requireCamera === 'boolean'
        ? value.requireCamera
        : DEFAULT_EXAM_SETTINGS.requireCamera,
    allowQuestionSkip:
      typeof value.allowQuestionSkip === 'boolean'
        ? value.allowQuestionSkip
        : DEFAULT_EXAM_SETTINGS.allowQuestionSkip,
    showResultsAfterClose:
      typeof value.showResultsAfterClose === 'boolean'
        ? value.showResultsAfterClose
        : DEFAULT_EXAM_SETTINGS.showResultsAfterClose,
    maxViolationCount:
      typeof value.maxViolationCount === 'number' &&
      Number.isInteger(value.maxViolationCount) &&
      value.maxViolationCount >= 1
        ? value.maxViolationCount
        : DEFAULT_EXAM_SETTINGS.maxViolationCount,
  };
};

/** Parses the persisted JSON `options` column into a strict option list. */
export const parseOptions = (raw: unknown): ExamOption[] => {
  if (!Array.isArray(raw)) return [];
  const seen = new Set<string>();
  const options: ExamOption[] = [];
  for (const entry of raw) {
    if (!entry || typeof entry !== 'object') continue;
    const candidate = entry as Record<string, unknown>;
    const id = typeof candidate.id === 'string' ? candidate.id.trim() : '';
    const text = typeof candidate.text === 'string' ? candidate.text.trim() : '';
    if (!id || !text || seen.has(id)) continue;
    seen.add(id);
    options.push({ id, text });
  }
  return options;
};

export const parseCorrectOptionIds = (raw: unknown): string[] => {
  if (!Array.isArray(raw)) return [];
  return raw.filter((value): value is string => typeof value === 'string' && value.length > 0);
};

export const isExamOpen = (
  status: ExamStatus,
  startsAt: Date,
  endsAt: Date,
  now: Date,
): boolean => status === 'PUBLISHED' && now >= startsAt && now <= endsAt;

export const computeExpiresAt = (
  startedAt: Date,
  durationMinutes: number,
  examEndsAt: Date,
): Date => {
  const byDuration = new Date(startedAt.getTime() + durationMinutes * 60_000);
  return byDuration < examEndsAt ? byDuration : examEndsAt;
};

export const remainingMs = (expiresAt: Date, now: Date): number =>
  Math.max(0, expiresAt.getTime() - now.getTime());

export const isAnswerAllowed = (question: ExamQuestion, optionIds: string[]): boolean => {
  if (optionIds.length === 0) return true; // clearing an answer is allowed
  if (question.type === 'SINGLE_CHOICE' && optionIds.length !== 1) return false;
  const validIds = new Set(question.options.map((option) => option.id));
  return optionIds.every((id) => validIds.has(id));
};

export interface GradedQuestion {
  questionId: string;
  correct: boolean;
  pointsAwarded: number;
  pointsMax: number;
}

export interface GradeResult {
  score: number;
  maxScore: number;
  correctCount: number;
  graded: GradedQuestion[];
}

/**
 * Server-side correction (RG19). Single-choice questions are all-or-nothing:
 * exactly one selected id must match the single correct id.
 */
export const gradeAttempt = (
  questions: ExamQuestion[],
  answers: ExamAnswer[],
): GradeResult => {
  const answerByQuestion = new Map(answers.map((answer) => [answer.questionId, answer]));
  let score = 0;
  let maxScore = 0;
  let correctCount = 0;
  const graded: GradedQuestion[] = [];

  for (const question of questions) {
    maxScore += question.points;
    const selected = answerByQuestion.get(question.id)?.selectedOptionIds ?? [];
    const correct =
      question.correctOptionIds.length === 1 &&
      selected.length === 1 &&
      selected[0] === question.correctOptionIds[0];
    if (correct) {
      score += question.points;
      correctCount += 1;
    }
    graded.push({
      questionId: question.id,
      correct,
      pointsAwarded: correct ? question.points : 0,
      pointsMax: question.points,
    });
  }

  return { score, maxScore, correctCount, graded };
};

export type SanctionDecision = 'NONE' | 'WARNING' | 'TERMINATED';

export interface SanctionResult {
  severity: ExamSeverity;
  decision: SanctionDecision;
  reason: string | null;
}

/**
 * Deterministic anti-fraud policy applied server-side (the client only
 * reports signals; it never decides a sanction).
 *
 * - Technical interruptions (network, camera permission) are recorded only.
 * - A confirmed environment exit (tab/app/page/fullscreen) terminates on the
 *   first occurrence once it lasted at least [MIN_CONFIRMED_EXIT_MS]; shorter
 *   blips are recorded as warnings.
 * - Copy/paste/context-menu/screenshot attempts accumulate: warning, then
 *   termination when `maxViolationCount` confirmed violations is reached.
 * - `FOCUS_LOST` and off-screen gaze are warnings only (no false positive
 *   termination on a blink or a transient detector miss).
 */
export const decideSanction = (params: {
  type: ExamEventType;
  durationMs: number | null;
  previousViolations: number;
  settings: ExamSettings;
}): SanctionResult => {
  const { type, durationMs, previousViolations, settings } = params;

  if (TECHNICAL_EVENT_TYPES.includes(type)) {
    return { severity: 'LOW', decision: 'NONE', reason: null };
  }

  if (CONFIRMED_EXIT_EVENT_TYPES.includes(type)) {
    const confirmed = durationMs === null || durationMs >= MIN_CONFIRMED_EXIT_MS;
    if (confirmed) {
      return {
        severity: 'HIGH',
        decision: 'TERMINATED',
        reason: `confirmed_exit:${type}`,
      };
    }
    return {
      severity: 'MEDIUM',
      decision: 'WARNING',
      reason: 'transient_exit_below_grace_period',
    };
  }

  if (COPY_PASTE_EVENT_TYPES.includes(type)) {
    const nextCount = previousViolations + 1;
    const decision: SanctionDecision =
      nextCount >= settings.maxViolationCount ? 'TERMINATED' : 'WARNING';
    return {
      severity: 'MEDIUM',
      decision,
      reason: decision === 'TERMINATED' ? `repeated_violation:${type}` : null,
    };
  }

  if (type === 'SCREENSHOT_ATTEMPT') {
    const nextCount = previousViolations + 1;
    const decision: SanctionDecision =
      nextCount >= settings.maxViolationCount ? 'TERMINATED' : 'WARNING';
    return {
      severity: 'MEDIUM',
      decision,
      reason: decision === 'TERMINATED' ? 'repeated_screenshot_attempts' : null,
    };
  }

  if (type === 'FOCUS_LOST' || type === 'CONTEXT_MENU' || type === 'GAZE_OFF_SCREEN') {
    return { severity: 'LOW', decision: 'WARNING', reason: null };
  }

  return { severity: 'LOW', decision: 'NONE', reason: null };
};
