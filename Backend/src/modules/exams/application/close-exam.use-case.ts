import { gradeAttempt } from '../domain/exam-policy.js';
import type { Role } from '../../auth/index.js';
import type { ExamDetail } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { loadExamForTeacher } from './exam-access.js';

export interface CloseExamDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
}

export interface CloseExamResult {
  exam: ExamDetail;
  finalizedAttempts: number;
}

/**
 * Closing releases results (when `showResultsAfterClose` is enabled) and
 * freezes every remaining attempt as AUTO_SUBMITTED using server-side
 * grading. No student can submit after this point.
 */
export class CloseExamUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: CloseExamDTO): Promise<CloseExamResult> {
    const exam = await loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    if (exam.status === 'CLOSED') return { exam, finalizedAttempts: 0 };

    const closed = await this.exams.setExamStatus(exam.id, 'CLOSED', exam.status === 'PUBLISHED' ? new Date() : null);
    const attempts = await this.exams.listAttemptsByExam(exam.id);
    let finalizedAttempts = 0;
    const now = new Date();
    for (const attempt of attempts) {
      if (attempt.status !== 'IN_PROGRESS') continue;
      const grade = gradeAttempt(exam.questions, attempt.answers ?? []);
      await this.exams.finalizeAttempt(attempt.id, {
        status: 'AUTO_SUBMITTED',
        submittedAt: now,
        score: grade.score,
        maxScore: grade.maxScore,
        terminatedReason: null,
      });
      finalizedAttempts += 1;
    }
    return { exam: closed, finalizedAttempts };
  }
}
