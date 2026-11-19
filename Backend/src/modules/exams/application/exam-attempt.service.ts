import { gradeAttempt } from '../domain/exam-policy.js';
import type { ExamAttemptDetail, ExamDetail } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';

/**
 * Centralises attempt lifecycle so every entry point (start, save, submit,
 * event, teacher close, results) uses the exact same server clock and the
 * exact same server-side grading. The student client can never finalize an
 * attempt by itself.
 */
export class ExamAttemptService {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public isTerminal(attempt: ExamAttemptDetail): boolean {
    return attempt.status !== 'IN_PROGRESS';
  }

  /**
   * Auto-submits an attempt once its server-side deadline passed (or once the
   * teacher closed the exam). Returns the up-to-date attempt.
   */
  public async autoFinalizeIfDue(
    exam: ExamDetail,
    attempt: ExamAttemptDetail,
    now: Date = new Date(),
  ): Promise<ExamAttemptDetail> {
    if (this.isTerminal(attempt)) return attempt;
    const expired = now.getTime() >= attempt.expiresAt.getTime();
    const examClosed = exam.status === 'CLOSED';
    if (!expired && !examClosed) return attempt;

    const grade = gradeAttempt(exam.questions, attempt.answers);
    return this.exams.finalizeAttempt(attempt.id, {
      status: 'AUTO_SUBMITTED',
      submittedAt: now,
      score: grade.score,
      maxScore: grade.maxScore,
      terminatedReason: null,
    });
  }

  public async submit(
    exam: ExamDetail,
    attempt: ExamAttemptDetail,
    now: Date = new Date(),
  ): Promise<{ attempt: ExamAttemptDetail; autoSubmitted: boolean }> {
    if (this.isTerminal(attempt)) return { attempt, autoSubmitted: false };
    if (now.getTime() >= attempt.expiresAt.getTime()) {
      const grade = gradeAttempt(exam.questions, attempt.answers);
      const finalized = await this.exams.finalizeAttempt(attempt.id, {
        status: 'AUTO_SUBMITTED',
        submittedAt: now,
        score: grade.score,
        maxScore: grade.maxScore,
        terminatedReason: null,
      });
      return { attempt: finalized, autoSubmitted: true };
    }

    const grade = gradeAttempt(exam.questions, attempt.answers);
    const finalized = await this.exams.finalizeAttempt(attempt.id, {
      status: 'SUBMITTED',
      submittedAt: now,
      score: grade.score,
      maxScore: grade.maxScore,
      terminatedReason: null,
    });
    return { attempt: finalized, autoSubmitted: false };
  }

  public async terminate(
    exam: ExamDetail,
    attempt: ExamAttemptDetail,
    reason: string,
    now: Date = new Date(),
  ): Promise<ExamAttemptDetail> {
    if (this.isTerminal(attempt)) return attempt;
    const grade = gradeAttempt(exam.questions, attempt.answers);
    return this.exams.finalizeAttempt(attempt.id, {
      status: 'TERMINATED',
      submittedAt: now,
      score: grade.score,
      maxScore: grade.maxScore,
      terminatedReason: reason,
    });
  }
}
