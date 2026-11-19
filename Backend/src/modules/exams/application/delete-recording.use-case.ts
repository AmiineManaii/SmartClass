import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { StoragePort } from '../../../shared/storage/storage.port.js';
import type { Role } from '../../auth/index.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { loadExamForTeacher } from './exam-access.js';

export interface DeleteRecordingDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
  recordingId: string;
}

/**
 * Manual deletion endpoint backing the retention policy. Deleting removes
 * both the DB row and the stored media file.
 */
export class DeleteRecordingUseCase {
  constructor(
    private readonly exams: ExamRepositoryPort,
    private readonly storage: StoragePort,
  ) {}

  public async execute(dto: DeleteRecordingDTO): Promise<{ deleted: true }> {
    const exam = await loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    const recording = await this.exams.findRecordingById(dto.recordingId);
    if (!recording || recording.examId !== exam.id) {
      throw new NotFoundError('Recording not found for this exam');
    }
    await this.storage.delete(recording.storageKey);
    await this.exams.deleteRecording(recording.id);
    return { deleted: true };
  }
}
