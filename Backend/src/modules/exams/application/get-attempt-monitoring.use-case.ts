import { NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type {
  ExamEvent,
  ExamQuestion,
  ExamRecording,
} from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { loadExamForTeacher } from './exam-access.js';

export interface GetAttemptMonitoringDTO {
  requesterId: string;
  requesterRole: Role | null;
  examId: string;
  attemptId: string;
}

export interface RecordingView {
  id: string;
  attemptId: string;
  examId: string;
  kind: string;
  mimeType: string;
  sizeBytes: number | null;
  durationMs: number | null;
  eventId: string | null;
  createdAt: Date;
}

export interface AttemptMonitoringView {
  examId: string;
  examTitle: string;
  questionCount: number;
  attempt: {
    id: string;
    studentId: string;
    studentName: string;
    status: string;
    startedAt: Date;
    expiresAt: Date;
    submittedAt: Date | null;
    score: number | null;
    maxScore: number;
    violationCount: number;
    terminatedReason: string | null;
    answers: { questionId: string; selectedOptionIds: string[]; savedAt: Date }[];
  };
  events: ExamEvent[];
  recordings: RecordingView[];
  /** Teacher-only; never returned by a student endpoint. */
  questions: ExamQuestion[];
}

const toRecordingView = (recording: ExamRecording): RecordingView => ({
  id: recording.id,
  attemptId: recording.attemptId,
  examId: recording.examId,
  kind: recording.kind,
  mimeType: recording.mimeType,
  sizeBytes: recording.sizeBytes,
  durationMs: recording.durationMs,
  eventId: recording.eventId,
  createdAt: recording.createdAt,
});

export class GetAttemptMonitoringUseCase {
  constructor(private readonly exams: ExamRepositoryPort) {}

  public async execute(dto: GetAttemptMonitoringDTO): Promise<AttemptMonitoringView> {
    const exam = await loadExamForTeacher(this.exams, dto.examId, {
      id: dto.requesterId,
      role: dto.requesterRole,
    });
    const attempt = await this.exams.findAttemptById(dto.attemptId);
    if (!attempt || attempt.examId !== exam.id) {
      throw new NotFoundError('Attempt not found for this exam');
    }
    const [events, recordings] = await Promise.all([
      this.exams.listEventsByAttempt(attempt.id),
      this.exams.listRecordingsByAttempt(attempt.id),
    ]);

    return {
      examId: exam.id,
      examTitle: exam.title,
      questionCount: exam.questions.length,
      attempt: {
        id: attempt.id,
        studentId: attempt.studentId,
        studentName: attempt.studentName,
        status: attempt.status,
        startedAt: attempt.startedAt,
        expiresAt: attempt.expiresAt,
        submittedAt: attempt.submittedAt,
        score: attempt.score,
        maxScore: attempt.maxScore,
        violationCount: attempt.violationCount,
        terminatedReason: attempt.terminatedReason,
        answers: attempt.answers.map((answer) => ({
          questionId: answer.questionId,
          selectedOptionIds: answer.selectedOptionIds,
          savedAt: answer.savedAt,
        })),
      },
      events,
      recordings: recordings.map(toRecordingView),
      questions: exam.questions,
    };
  }
}
