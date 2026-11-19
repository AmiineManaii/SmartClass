import {
  ExamAttemptClosedError,
  NotFoundError,
  ValidationError,
} from '../../../shared/errors/app-error.js';
import { isAnswerAllowed } from '../domain/exam-policy.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { assertStudentOfExam } from './exam-access.js';
import { ExamAttemptService } from './exam-attempt.service.js';
import { toStudentAnswerViews, type StudentAnswerView } from './exam-projection.js';

export interface SaveAnswerItem {
  questionId: string;
  selectedOptionIds: string[];
}

export interface SaveAnswersDTO {
  studentId: string;
  examId: string;
  answers: SaveAnswerItem[];
  now?: Date;
}

export interface SaveAnswersResult {
  savedAt: Date;
  answers: StudentAnswerView[];
  remainingMs: number;
  serverNow: Date;
}

/**
 * Saves (upserts) answers while the attempt is active. Expiry and closed
 * exams are checked BEFORE any write so an expired attempt cannot gain
 * answers after its deadline.
 */
export class SaveAnswersUseCase {
  private readonly lifecycle: ExamAttemptService;

  constructor(private readonly exams: ExamRepositoryPort) {
    this.lifecycle = new ExamAttemptService(exams);
  }

  public async execute(dto: SaveAnswersDTO): Promise<SaveAnswersResult> {
    const now = dto.now ?? new Date();
    const exam = await this.exams.findExamById(dto.examId);
    if (!exam) throw new NotFoundError('Exam not found');
    await assertStudentOfExam(this.exams, exam, dto.studentId);

    const existing = await this.exams.findAttemptByExamAndStudent(exam.id, dto.studentId);
    if (!existing) throw new NotFoundError('No attempt exists for this exam');
    const attempt = await this.lifecycle.autoFinalizeIfDue(exam, existing, now);
    if (attempt.status !== 'IN_PROGRESS') {
      throw new ExamAttemptClosedError('This attempt is already closed', [
        { status: attempt.status },
      ]);
    }

    const questionById = new Map(exam.questions.map((question) => [question.id, question]));
    const normalized = dto.answers.map((item, index) => {
      const question = questionById.get(item.questionId);
      if (!question) {
        throw new ValidationError('Answer targets an unknown question', [
          { path: `answers.${index}.questionId`, message: 'Question does not belong to this exam' },
        ]);
      }
      const selected = Array.from(new Set(item.selectedOptionIds));
      if (!isAnswerAllowed(question, selected)) {
        throw new ValidationError('Invalid answer option', [
          {
            path: `answers.${index}.selectedOptionIds`,
            message: 'Select one valid option from this question',
          },
        ]);
      }
      return { questionId: question.id, selectedOptionIds: selected };
    });

    for (const answer of normalized) {
      await this.exams.upsertAnswer(attempt.id, answer.questionId, answer.selectedOptionIds, now);
      await this.exams.touchAttempt(attempt.id, now);
    }

    const refreshed = await this.exams.findAttemptById(attempt.id);
    return {
      savedAt: now,
      answers: refreshed ? toStudentAnswerViews(refreshed) : [],
      remainingMs: Math.max(0, attempt.expiresAt.getTime() - now.getTime()),
      serverNow: now,
    };
  }
}
