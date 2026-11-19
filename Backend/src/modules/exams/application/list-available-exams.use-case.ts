import type {
  ExamAttemptStatus,
  ExamStatus,
  ExamSummary,
} from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';

export type ExamAvailability = 'UPCOMING' | 'ACTIVE' | 'ENDED' | 'CLOSED';

export interface AvailableExamView extends ExamSummary {
  availability: ExamAvailability;
  attemptStatus: ExamAttemptStatus | null;
  canStart: boolean;
  canResume: boolean;
  remainingMs: number | null;
}

export interface ListAvailableExamsDTO {
  studentId: string;
  now?: Date;
}

const availabilityFor = (
  status: ExamStatus,
  startsAt: Date,
  endsAt: Date,
  now: Date,
): ExamAvailability => {
  if (status === 'CLOSED') return 'CLOSED';
  if (now.getTime() < startsAt.getTime()) return 'UPCOMING';
  if (now.getTime() > endsAt.getTime()) return 'ENDED';
  return 'ACTIVE';
};

/** Every published exam addressed to one of the student's classes. */
export class ListAvailableExamsUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: ListAvailableExamsDTO): Promise<AvailableExamView[]> {
    const now = dto.now ?? new Date();
    const classIds = await this.exams.listStudentClassIds(dto.studentId);
    const [summaries, attempts] = await Promise.all([
      this.exams.listPublishedExamsForClasses(classIds),
      this.exams.listAttemptsByStudent(dto.studentId),
    ]);
    const attemptByExam = new Map(attempts.map((attempt) => [attempt.examId, attempt]));

    return summaries.map((summary) => {
      const attempt = attemptByExam.get(summary.id) ?? null;
      const availability = availabilityFor(summary.status, summary.startsAt, summary.endsAt, now);
      const inProgress = attempt?.status === 'IN_PROGRESS' && availability === 'ACTIVE';
      return {
        ...summary,
        availability,
        attemptStatus: attempt?.status ?? null,
        canStart: attempt === null && availability === 'ACTIVE',
        canResume: inProgress,
        remainingMs: inProgress ? Math.max(0, attempt.expiresAt.getTime() - now.getTime()) : null,
      };
    });
  }
}
