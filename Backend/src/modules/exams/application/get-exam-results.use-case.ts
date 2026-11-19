import { gradeAttempt } from '../domain/exam-policy.js';
import type { Role } from '../../auth/index.js';
import type { ExamResultEntry, ExamResults } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { loadExamForTeacher } from './exam-access.js';

export interface GetExamResultsDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
}

export class GetExamResultsUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: GetExamResultsDTO): Promise<ExamResults> {
    const exam = await loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    const attempts = await this.exams.listAttemptsByExam(exam.id);

    const results: ExamResultEntry[] = attempts.map((attempt) => {
      const grade = gradeAttempt(exam.questions, attempt.answers ?? []);
      return {
        attemptId: attempt.id,
        studentId: attempt.studentId,
        studentName: attempt.studentName,
        status: attempt.status,
        score: attempt.score ?? (attempt.status === 'IN_PROGRESS' ? null : grade.score),
        maxScore: grade.maxScore,
        correctCount: grade.correctCount,
        questionCount: exam.questions.length,
        submittedAt: attempt.submittedAt,
        violationCount: attempt.violationCount,
      };
    });

    const graded = results.filter((entry) => entry.score !== null);
    const averageScore =
      graded.length === 0
        ? null
        : graded.reduce((sum, entry) => sum + (entry.score ?? 0), 0) / graded.length;

    return {
      examId: exam.id,
      examTitle: exam.title,
      status: exam.status,
      attemptCount: results.length,
      averageScore,
      results,
    };
  }
}
