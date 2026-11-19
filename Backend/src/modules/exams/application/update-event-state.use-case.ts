import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { ExamEvent, ExamEventState } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { loadExamForTeacher } from './exam-access.js';

export interface UpdateEventStateDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
  eventId: string;
  state: ExamEventState;
}

export class UpdateEventStateUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: UpdateEventStateDTO): Promise<ExamEvent> {
    const exam = await loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    const event = await this.exams.findEventById(dto.eventId);
    if (!event || event.examId !== exam.id) {
      throw new NotFoundError('Event not found for this exam');
    }
    return this.exams.updateEventState(event.id, dto.state);
  }
}
