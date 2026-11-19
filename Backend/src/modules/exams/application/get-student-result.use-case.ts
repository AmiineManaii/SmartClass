import {
  ExamResultsNotAvailableError,
  NotFoundError,
} from '../../../shared/errors/app-error.js';
import { gradeAttempt } from '../domain/exam-policy.js';
import type { Role } from '../../auth/index.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { assertStudentOfExam } from './exam-access.js';

export interface GetStudentResultDTO {
  studentId: string;
  examId: string;
  requesterRole: Role | null;
}

export interface StudentResultItem {
  questionId: string;
  selectedOptionIds: string[];
  correct: boolean;
  pointsAwarded: number;
  pointsMax: number;
}

export interface StudentResultView {
  examId: string;
  examTitle: string;
  status: string;
  score: number;
  maxScore: number;
  correctCount: number;
  questionCount: number;
  submittedAt: Date | null;
  terminatedReason: string | null;
  items: StudentResultItem[];
}

/**
 * Student result projection: correctness per question only. Correct option
 * ids and explanations are NEVER sent to the student, even after release.
 */
export class GetStudentResultUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: GetStudentResultDTO): Promise<StudentResultView> {
    const exam = await this.exams.findExamById(dto.examId);
    if (!exam) throw new NotFoundError('Exam not found');
    await assertStudentOfExam(this.exams, exam, dto.studentId);

    const attempt = await this.exams.findAttemptByExamAndStudent(exam.id, dto.studentId);
    if (!attempt) throw new NotFoundError('No attempt exists for this exam');
    if (attempt.status === 'IN_PROGRESS') {
      throw new ExamResultsNotAvailableError('Your attempt is still in progress');
    }

    const released =
      exam.status === 'CLOSED' && (exam.settings.showResultsAfterClose || dto.requesterRole === 'ADMIN');
    if (!released) {
      throw new ExamResultsNotAvailableError(
        'Results will be available after the teacher closes the exam',
      );
    }

    const grade = gradeAttempt(exam.questions, attempt.answers);
    const answerByQuestion = new Map(
      attempt.answers.map((answer) => [answer.questionId, answer.selectedOptionIds]),
    );
    return {
      examId: exam.id,
      examTitle: exam.title,
      status: attempt.status,
      score: grade.score,
      maxScore: grade.maxScore,
      correctCount: grade.correctCount,
      questionCount: exam.questions.length,
      submittedAt: attempt.submittedAt,
      terminatedReason: attempt.terminatedReason,
      items: grade.graded.map((entry) => ({
        questionId: entry.questionId,
        selectedOptionIds: answerByQuestion.get(entry.questionId) ?? [],
        correct: entry.correct,
        pointsAwarded: entry.pointsAwarded,
        pointsMax: entry.pointsMax,
      })),
    };
  }
}
