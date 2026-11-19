import { ConflictError, ValidationError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { ExamDetail } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { loadExamForTeacher } from './exam-access.js';

export interface PublishExamDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
}

/**
 * RG4: only the teacher publishes. The AI and the import endpoints return
 * previews; nothing becomes visible to students before this call succeeds.
 */
export class PublishExamUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: PublishExamDTO): Promise<ExamDetail> {
    const exam = await loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    if (exam.status === 'PUBLISHED') return exam;
    if (exam.status === 'CLOSED') {
      throw new ConflictError('A closed exam cannot be published again');
    }
    if (exam.questions.length === 0) {
      throw new ValidationError('Cannot publish an exam without questions', [
        { path: 'questions', message: 'Add at least one question before publishing' },
      ]);
    }
    const now = new Date();
    if (exam.endsAt.getTime() <= now.getTime()) {
      throw new ValidationError('Cannot publish an exam whose end date is in the past', [
        { path: 'endsAt', message: 'Extend the exam window before publishing' },
      ]);
    }
    if (exam.endsAt.getTime() <= exam.startsAt.getTime()) {
      throw new ValidationError('Exam end must be after its start', [
        { path: 'endsAt', message: 'endsAt must be after startsAt' },
      ]);
    }

    return this.exams.setExamStatus(exam.id, 'PUBLISHED', now);
  }
}
