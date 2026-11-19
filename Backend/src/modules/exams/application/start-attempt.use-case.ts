import { ExamNotAvailableError, NotFoundError } from '../../../shared/errors/app-error.js';
import { computeExpiresAt } from '../domain/exam-policy.js';
import type { ExamAttemptDetail, ExamDetail } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { assertStudentOfExam } from './exam-access.js';
import { ExamAttemptService } from './exam-attempt.service.js';
import {
  toStudentAnswerViews,
  toStudentAttemptView,
  toStudentExamView,
  type StudentAnswerView,
  type StudentAttemptView,
  type StudentExamView,
} from './exam-projection.js';

export interface StartAttemptDTO {
  studentId: string;
  examId: string;
  now?: Date;
}

export interface StartAttemptResult {
  exam: StudentExamView;
  attempt: StudentAttemptView;
  answers: StudentAnswerView[];
  resumed: boolean;
  canResume: boolean;
  serverNow: Date;
}

const assertWindowOpen = (exam: ExamDetail, now: Date): void => {
  if (exam.status !== 'PUBLISHED') {
    throw new ExamNotAvailableError(
      exam.status === 'DRAFT'
        ? 'This exam is not published yet'
        : 'This exam is closed',
    );
  }
  if (now.getTime() < exam.startsAt.getTime()) {
    throw new ExamNotAvailableError('This exam has not started yet', [
      { startsAt: exam.startsAt },
    ]);
  }
  if (now.getTime() > exam.endsAt.getTime()) {
    throw new ExamNotAvailableError('This exam window has ended', [{ endsAt: exam.endsAt }]);
  }
};

/** Starts (or resumes) the single server-owned attempt of a student. */
export class StartAttemptUseCase {
  private readonly lifecycle: ExamAttemptService;

  constructor(private readonly exams: ExamRepositoryPort) {
    this.lifecycle = new ExamAttemptService(exams);
  }

  public async execute(dto: StartAttemptDTO): Promise<StartAttemptResult> {
    const now = dto.now ?? new Date();
    const exam = await this.exams.findExamById(dto.examId);
    if (!exam) throw new NotFoundError('Exam not found');
    await assertStudentOfExam(this.exams, exam, dto.studentId);

    const existing = await this.exams.findAttemptByExamAndStudent(exam.id, dto.studentId);
    if (existing) {
      const attempt = await this.lifecycle.autoFinalizeIfDue(exam, existing, now);
      return this.buildResult(exam, attempt, now, true);
    }

    assertWindowOpen(exam, now);
    const maxScore = exam.questions.reduce((sum, question) => sum + question.points, 0);
    let attempt: ExamAttemptDetail;
    try {
      attempt = await this.exams.createAttempt({
        examId: exam.id,
        studentId: dto.studentId,
        startedAt: now,
        expiresAt: computeExpiresAt(now, exam.durationMinutes, exam.endsAt),
        maxScore,
      });
    } catch (error) {
      // Concurrent double-start: the unique (examId, studentId) constraint
      // wins the race; return the attempt that was actually created.
      const raced = await this.exams.findAttemptByExamAndStudent(exam.id, dto.studentId);
      if (!raced) throw error;
      attempt = raced;
    }

    return this.buildResult(exam, attempt, now, false);
  }

  private buildResult(
    exam: ExamDetail,
    attempt: ExamAttemptDetail,
    now: Date,
    resumed: boolean,
  ): StartAttemptResult {
    const canResume = attempt.status === 'IN_PROGRESS';
    return {
      exam: toStudentExamView(exam, now, attempt.id),
      attempt: toStudentAttemptView(attempt, now),
      answers: canResume ? toStudentAnswerViews(attempt) : [],
      resumed,
      canResume,
      serverNow: now,
    };
  }
}
