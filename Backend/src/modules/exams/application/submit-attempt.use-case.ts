import { ExamAttemptClosedError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { assertStudentOfExam } from './exam-access.js';
import { ExamAttemptService } from './exam-attempt.service.js';
import { toStudentAttemptView, type StudentAttemptView } from './exam-projection.js';

export interface SubmitAttemptDTO {
  studentId: string;
  examId: string;
  now?: Date;
}

export interface SubmitAttemptResult {
  attempt: StudentAttemptView;
  autoSubmitted: boolean;
  serverNow: Date;
}

export class SubmitAttemptUseCase {
  private readonly lifecycle: ExamAttemptService;

  constructor(private readonly exams: ExamRepositoryPort) {
    this.lifecycle = new ExamAttemptService(exams);
  }

  public async execute(dto: SubmitAttemptDTO): Promise<SubmitAttemptResult> {
    const now = dto.now ?? new Date();
    const exam = await this.exams.findExamById(dto.examId);
    if (!exam) throw new NotFoundError('Exam not found');
    await assertStudentOfExam(this.exams, exam, dto.studentId);

    const existing = await this.exams.findAttemptByExamAndStudent(exam.id, dto.studentId);
    if (!existing) throw new NotFoundError('No attempt exists for this exam');
    if (existing.status !== 'IN_PROGRESS') {
      throw new ExamAttemptClosedError('This attempt has already been submitted', [
        { status: existing.status, submittedAt: existing.submittedAt },
      ]);
    }

    const due = await this.lifecycle.autoFinalizeIfDue(exam, existing, now);
    if (due.status !== 'IN_PROGRESS') {
      // Deadline already passed or teacher closed the exam: block a second submit.
      throw new ExamAttemptClosedError('This attempt is already closed', [
        { status: due.status },
      ]);
    }

    const { attempt, autoSubmitted } = await this.lifecycle.submit(exam, due, now);
    return {
      attempt: toStudentAttemptView(attempt, now),
      autoSubmitted,
      serverNow: now,
    };
  }
}
