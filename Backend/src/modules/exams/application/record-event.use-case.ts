import {
  ExamAttemptClosedError,
  NotFoundError,
} from '../../../shared/errors/app-error.js';
import { countsAsViolation, decideSanction } from '../domain/exam-policy.js';
import type {
  ExamEvent,
  ExamEventType,
  ExamSeverity,
} from '../domain/exam.entity.js';
import type { ExamRepositoryPort } from '../domain/exam-repository.port.js';
import { assertStudentOfExam } from './exam-access.js';
import { ExamAttemptService } from './exam-attempt.service.js';
import { toStudentAttemptView, type StudentAttemptView } from './exam-projection.js';

export interface RecordEventDTO {
  studentId: string;
  examId: string;
  type: ExamEventType;
  durationMs?: number | null;
  source?: string;
  clientOccurredAt?: string | null;
  metadata?: Record<string, unknown>;
  now?: Date;
}

export interface RecordEventResult {
  event: ExamEvent;
  attempt: StudentAttemptView;
  decision: 'NONE' | 'WARNING' | 'TERMINATED';
  severity: ExamSeverity;
  remainingMs: number;
  serverNow: Date;
}

/**
 * Anti-fraud ingestion. The client only reports a signal; the backend
 * timestamps it, decides the severity/decision and terminates when the
 * deterministic policy requires it. Network and camera-permission events
 * are recorded but never sanctioned.
 */
export class RecordEventUseCase {
  private readonly lifecycle: ExamAttemptService;

  constructor(private readonly exams: ExamRepositoryPort) {
    this.lifecycle = new ExamAttemptService(exams);
  }

  public async execute(dto: RecordEventDTO): Promise<RecordEventResult> {
    const now = dto.now ?? new Date();
    const exam = await this.exams.findExamById(dto.examId);
    if (!exam) throw new NotFoundError('Exam not found');
    await assertStudentOfExam(this.exams, exam, dto.studentId);

    const existing = await this.exams.findAttemptByExamAndStudent(exam.id, dto.studentId);
    if (!existing) throw new NotFoundError('No attempt exists for this exam');
    const attempt = await this.lifecycle.autoFinalizeIfDue(exam, existing, now);
    if (attempt.status !== 'IN_PROGRESS') {
      throw new ExamAttemptClosedError('This attempt is already closed', [
        { status: attempt.status },
      ]);
    }

    const durationMs =
      dto.durationMs === undefined || dto.durationMs === null
        ? null
        : Math.max(0, Math.min(24 * 60 * 60 * 1000, Math.trunc(dto.durationMs)));
    const sanction = decideSanction({
      type: dto.type,
      durationMs,
      previousViolations: attempt.violationCount,
      settings: exam.settings,
    });

    const metadata: Record<string, unknown> = {
      ...(dto.metadata ?? {}),
      ...(dto.clientOccurredAt ? { clientOccurredAt: dto.clientOccurredAt } : {}),
      serverReceivedAt: now.toISOString(),
    };

    const event = await this.exams.createEvent({
      attemptId: attempt.id,
      examId: exam.id,
      studentId: dto.studentId,
      type: dto.type,
      severity: sanction.severity,
      occurredAt: now,
      durationMs,
      source: (dto.source ?? 'unknown').slice(0, 20),
      metadata,
      decision: sanction.decision,
    });

    let violationCount = attempt.violationCount;
    if (sanction.decision === 'WARNING' && countsAsViolation(dto.type)) {
      violationCount = attempt.violationCount + 1;
      await this.exams.setAttemptViolationCount(attempt.id, violationCount);
    }

    let updatedAttempt = attempt;
    if (sanction.decision === 'TERMINATED') {
      updatedAttempt = await this.lifecycle.terminate(
        exam,
        attempt,
        sanction.reason ?? `violation:${dto.type}`,
        now,
      );
    }

    return {
      event,
      attempt: toStudentAttemptView(
        { ...updatedAttempt, violationCount },
        now,
      ),
      decision: sanction.decision,
      severity: sanction.severity,
      remainingMs: Math.max(0, attempt.expiresAt.getTime() - now.getTime()),
      serverNow: now,
    };
  }
}
