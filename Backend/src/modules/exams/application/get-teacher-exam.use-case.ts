import type { Role } from '../../auth/index.js';
import type { ExamDetail } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { loadExamForTeacher } from './exam-access.js';

export interface GetTeacherExamDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
}

/** Teacher-only projection: includes correct answers and explanations. */
export class GetTeacherExamUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: GetTeacherExamDTO): Promise<ExamDetail> {
    return loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
  }
}
