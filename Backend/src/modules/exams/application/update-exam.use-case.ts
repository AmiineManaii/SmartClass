import { ConflictError, ValidationError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import { normalizeSettings } from '../domain/exam-policy.js';
import type { ExamDetail, ExamSettings } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { normalizeQuestionInputs } from './exam-input.js';
import { loadExamForTeacher } from './exam-access.js';

export interface UpdateExamDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
  title?: string;
  description?: string | null;
  durationMinutes?: number;
  startsAt?: Date;
  endsAt?: Date;
  settings?: Partial<ExamSettings>;
  /** When present, replaces the whole question list. */
  questions?: unknown;
}

export class UpdateExamUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: UpdateExamDTO): Promise<ExamDetail> {
    const exam = await loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    if (exam.status !== 'DRAFT') {
      throw new ConflictError('Published or closed exams can no longer be edited');
    }

    const startsAt = dto.startsAt ?? exam.startsAt;
    const endsAt = dto.endsAt ?? exam.endsAt;
    if (endsAt.getTime() <= startsAt.getTime()) {
      throw new ValidationError('Exam end must be after its start', [
        { path: 'endsAt', message: 'endsAt must be after startsAt' },
      ]);
    }

    return this.exams.updateExam(dto.examId, {
      ...(dto.title !== undefined ? { title: dto.title.trim() } : {}),
      ...(dto.description !== undefined
        ? { description: dto.description?.trim() || null }
        : {}),
      ...(dto.durationMinutes !== undefined ? { durationMinutes: dto.durationMinutes } : {}),
      ...(dto.startsAt !== undefined ? { startsAt: dto.startsAt } : {}),
      ...(dto.endsAt !== undefined ? { endsAt: dto.endsAt } : {}),
      ...(dto.settings !== undefined
        ? { settings: normalizeSettings({ ...exam.settings, ...dto.settings }) }
        : {}),
      ...(dto.questions !== undefined
        ? { questions: normalizeQuestionInputs(dto.questions) }
        : {}),
    });
  }
}
