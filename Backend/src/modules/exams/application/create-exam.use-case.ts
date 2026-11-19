import { BadRequestError, ValidationError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import { normalizeSettings } from '../domain/exam-policy.js';
import type { ExamDetail, ExamSettings, ExamSource } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { normalizeQuestionInputs } from './exam-input.js';
import { assertCanUseClass } from './exam-access.js';

export interface CreateExamDTO {
  requesterId: string;
  requesterRole: Role | null;
  title: string;
  description?: string | null;
  classGroupId: string;
  durationMinutes: number;
  startsAt: Date;
  endsAt: Date;
  settings?: Partial<ExamSettings>;
  source?: ExamSource;
  questions: unknown;
}

const assertWindow = (startsAt: Date, endsAt: Date): void => {
  if (Number.isNaN(startsAt.getTime()) || Number.isNaN(endsAt.getTime())) {
    throw new BadRequestError('Invalid exam window');
  }
  if (endsAt.getTime() <= startsAt.getTime()) {
    throw new ValidationError('Exam end must be after its start', [
      { path: 'endsAt', message: 'endsAt must be after startsAt' },
    ]);
  }
};

export class CreateExamUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: CreateExamDTO): Promise<ExamDetail> {
    const classGroup = await this.exams.findClassGroup(dto.classGroupId);
    if (!classGroup) {
      throw new ValidationError('Unknown class', [
        { path: 'classGroupId', message: 'This class does not exist' },
      ]);
    }
    await assertCanUseClass(this.exams, dto.classGroupId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    assertWindow(dto.startsAt, dto.endsAt);

    const questions = normalizeQuestionInputs(dto.questions);

    return this.exams.createExam({
      title: dto.title.trim(),
      description: dto.description?.trim() || null,
      classGroupId: dto.classGroupId,
      authorId: dto.requesterId,
      durationMinutes: dto.durationMinutes,
      startsAt: dto.startsAt,
      endsAt: dto.endsAt,
      source: dto.source ?? 'MANUAL',
      settings: normalizeSettings(dto.settings),
      questions,
    });
  }
}
