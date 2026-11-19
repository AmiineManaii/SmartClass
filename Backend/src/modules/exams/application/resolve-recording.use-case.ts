import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { loadExamForTeacher } from './exam-access.js';

export interface ResolveRecordingDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
  recordingId: string;
}

export interface ResolvedRecording {
  storageKey: string;
  mimeType: string;
  sizeBytes: number | null;
}

/** Teacher-only access check before a Range stream is opened. */
export class ResolveRecordingUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: ResolveRecordingDTO): Promise<ResolvedRecording> {
    const exam = await loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    const recording = await this.exams.findRecordingById(dto.recordingId);
    if (!recording || recording.examId !== exam.id) {
      throw new NotFoundError('Recording not found for this exam');
    }
    return {
      storageKey: recording.storageKey,
      mimeType: recording.mimeType,
      sizeBytes: recording.sizeBytes,
    };
  }
}
