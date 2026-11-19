import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { assertStudentOfExam } from './exam-access.js';
import { ExamAttemptService } from './exam-attempt.service.js';
import {
  toStudentAnswerViews,
  toStudentAttemptView,
  toStudentExamView,
} from './exam-projection.js';
import type { StartAttemptResult } from './start-attempt.use-case.js';

export interface GetAttemptDTO {
  studentId: string;
  examId: string;
  now?: Date;
}

/** Resumes the student's attempt without ever creating a new one. */
export class GetAttemptUseCase {
  private readonly lifecycle: ExamAttemptService;

  constructor(private readonly exams: ExamRepositoryPort) {
    this.lifecycle = new ExamAttemptService(exams);
  }

  public async execute(dto: GetAttemptDTO): Promise<StartAttemptResult> {
    const now = dto.now ?? new Date();
    const exam = await this.exams.findExamById(dto.examId);
    if (!exam) throw new NotFoundError('Exam not found');
    await assertStudentOfExam(this.exams, exam, dto.studentId);

    const existing = await this.exams.findAttemptByExamAndStudent(exam.id, dto.studentId);
    if (!existing) throw new NotFoundError('No attempt exists for this exam');
    const attempt = await this.lifecycle.autoFinalizeIfDue(exam, existing, now);
    const canResume = attempt.status === 'IN_PROGRESS';

    return {
      exam: toStudentExamView(exam, now, attempt.id),
      attempt: toStudentAttemptView(attempt, now),
      answers: canResume ? toStudentAnswerViews(attempt) : [],
      resumed: true,
      canResume,
      serverNow: now,
    };
  }
}
