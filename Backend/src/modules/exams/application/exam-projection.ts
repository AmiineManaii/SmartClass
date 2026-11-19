import type {
  ExamAttemptDetail,
  ExamDetail,
  ExamSettings,
  StudentExamQuestion,
} from '../domain/exam.entity.js';

export interface StudentExamView {
  id: string;
  title: string;
  description: string | null;
  className: string | null;
  durationMinutes: number;
  startsAt: Date;
  endsAt: Date;
  status: string;
  settings: Pick<ExamSettings, 'requireCamera' | 'allowQuestionSkip' | 'shuffleQuestions'>;
  questionCount: number;
  totalPoints: number;
  questions: StudentExamQuestion[];
  serverNow: Date;
}

/** Student attempt projection: never carries correct answers nor explanations. */
export interface StudentAttemptView {
  id: string;
  examId: string;
  status: string;
  startedAt: Date;
  expiresAt: Date;
  submittedAt: Date | null;
  remainingMs: number;
  violationCount: number;
  terminatedReason: string | null;
}

const hash = (value: string): number => {
  let total = 0;
  for (let index = 0; index < value.length; index += 1) {
    total = (total * 31 + value.charCodeAt(index)) >>> 0;
  }
  return total;
};

/**
 * Deterministic shuffle: the same attempt always sees the same order, so a
 * refresh or a resume never reshuffles the questions under the student.
 */
const orderForAttempt = (
  questions: ExamDetail['questions'],
  settings: ExamSettings,
  attemptId: string | null,
): ExamDetail['questions'] => {
  if (!settings.shuffleQuestions || !attemptId) return questions;
  return questions
    .slice()
    .sort((a, b) => hash(`${attemptId}:${a.id}`) - hash(`${attemptId}:${b.id}`));
};

export const toStudentExamView = (
  exam: ExamDetail,
  now: Date,
  attemptId: string | null = null,
): StudentExamView => ({
  id: exam.id,
  title: exam.title,
  description: exam.description,
  className: exam.className,
  durationMinutes: exam.durationMinutes,
  startsAt: exam.startsAt,
  endsAt: exam.endsAt,
  status: exam.status,
  settings: {
    requireCamera: exam.settings.requireCamera,
    allowQuestionSkip: exam.settings.allowQuestionSkip,
    shuffleQuestions: exam.settings.shuffleQuestions,
  },
  questionCount: exam.questions.length,
  totalPoints: exam.questions.reduce((sum, question) => sum + question.points, 0),
  questions: orderForAttempt(exam.questions, exam.settings, attemptId).map((question, index) => ({
    id: question.id,
    order: index + 1,
    type: question.type,
    prompt: question.prompt,
    hint: question.hint,
    options: question.options,
    points: question.points,
  })),
  serverNow: now,
});

export const toStudentAttemptView = (
  attempt: ExamAttemptDetail,
  now: Date,
): StudentAttemptView => ({
  id: attempt.id,
  examId: attempt.examId,
  status: attempt.status,
  startedAt: attempt.startedAt,
  expiresAt: attempt.expiresAt,
  submittedAt: attempt.submittedAt,
  remainingMs: Math.max(0, attempt.expiresAt.getTime() - now.getTime()),
  violationCount: attempt.violationCount,
  terminatedReason: attempt.terminatedReason,
});

export interface StudentAnswerView {
  questionId: string;
  selectedOptionIds: string[];
  savedAt: Date;
}

export const toStudentAnswerViews = (attempt: ExamAttemptDetail): StudentAnswerView[] =>
  attempt.answers.map((answer) => ({
    questionId: answer.questionId,
    selectedOptionIds: answer.selectedOptionIds,
    savedAt: answer.savedAt,
  }));
