import { randomUUID } from 'node:crypto';
import { getEnv } from '../../../config/env.js';
import {
  NotFoundError,
  ValidationError,
} from '../../../shared/errors/app-error.js';
import type { StoragePort } from '../../../shared/storage/storage.port.js';
import type { ExamRecording } from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';

export interface SaveRecordingDTO {
  studentId: string;
  examId: string;
  attemptId?: string;
  eventId?: string | null;
  kind?: string;
  mimeType: string;
  durationMs?: number | null;
  data: Buffer;
}

export interface RecordingView {
  id: string;
  attemptId: string;
  examId: string;
  eventId: string | null;
  kind: string;
  mimeType: string;
  sizeBytes: number | null;
  durationMs: number | null;
  createdAt: Date;
}

const toView = (recording: ExamRecording): RecordingView => ({
  id: recording.id,
  attemptId: recording.attemptId,
  examId: recording.examId,
  eventId: recording.eventId,
  kind: recording.kind,
  mimeType: recording.mimeType,
  sizeBytes: recording.sizeBytes,
  durationMs: recording.durationMs,
  createdAt: recording.createdAt,
});

const MIME_EXTENSIONS: Record<string, string> = {
  'video/webm': 'webm',
  'video/mp4': 'mp4',
};

/**
 * Stores one short evidence segment uploaded by the student client after an
 * event. A missing recording means no video proof exists; the UI must not
 * invent one.
 */
export class SaveRecordingUseCase {
  constructor(
    private readonly exams: ExamRepositoryPort,
    private readonly storage: StoragePort,
  ) {}

  public async execute(dto: SaveRecordingDTO): Promise<RecordingView> {
    const attempt = dto.attemptId
      ? await this.exams.findAttemptById(dto.attemptId)
      : await this.exams.findAttemptByExamAndStudent(dto.examId, dto.studentId);
    if (!attempt || attempt.examId !== dto.examId || attempt.studentId !== dto.studentId) {
      throw new NotFoundError('Attempt not found for this student and exam');
    }

    if (dto.eventId) {
      const event = await this.exams.findEventById(dto.eventId);
      if (!event || event.attemptId !== attempt.id) {
        throw new ValidationError('Recording targets an unknown event', [
          { path: 'eventId', message: 'Event does not belong to this attempt' },
        ]);
      }
    }

    const baseMime = dto.mimeType.split(';')[0]?.trim().toLowerCase() ?? '';
    const extension = MIME_EXTENSIONS[baseMime];
    if (!extension) {
      throw new ValidationError('Unsupported video format', [
        { path: 'file', message: 'Upload a WebM or MP4 segment' },
      ]);
    }
    if (!dto.data || dto.data.length === 0) {
      throw new ValidationError('The recording segment is empty', [
        { path: 'file', message: 'Upload a non-empty video segment' },
      ]);
    }
    const maxBytes = getEnv().STORAGE_MAX_UPLOAD_MB * 1024 * 1024;
    if (dto.data.length > maxBytes) {
      throw new ValidationError('Recording segment too large', [
        { path: 'file', message: `Maximum size is ${getEnv().STORAGE_MAX_UPLOAD_MB} MB` },
      ]);
    }

    const storageKey = `exam-recordings/${dto.examId}/${dto.attemptId}/${randomUUID()}.${extension}`;
    const stat = await this.storage.writeBuffer(storageKey, dto.data);
    const recording = await this.exams.createRecording({
      attemptId: attempt.id,
      examId: dto.examId,
      studentId: dto.studentId,
      eventId: dto.eventId ?? null,
      kind: (dto.kind ?? 'SEGMENT').slice(0, 40),
      storageKey: stat.key,
      mimeType: baseMime,
      sizeBytes: stat.sizeBytes,
      durationMs:
        dto.durationMs === undefined || dto.durationMs === null
          ? null
          : Math.max(0, Math.trunc(dto.durationMs)),
    });
    return toView(recording);
  }
}
