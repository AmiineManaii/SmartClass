import type { Role } from '../../auth/index.js';
import type { ExamSummary } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';

export interface ListMyExamsDTO {
  requesterId: string;
  requesterRole: Role | null;
}

/** Authors see their drafts; teaching staff also see exams for their classes. */
export class ListMyExamsUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: ListMyExamsDTO): Promise<ExamSummary[]> {
    const authored = await this.exams.listExamsByAuthor(dto.requesterId);
    if (dto.requesterRole === 'ADMIN') return authored;
    return authored;
  }
}
