import type { Request, Response, NextFunction } from 'express';
import type { ExamEventType } from '../domain/exam.entity.js';
import type { ListAvailableExamsUseCase } from '../application/list-available-exams.use-case.js';
import type { StartAttemptUseCase } from '../application/start-attempt.use-case.js';
import type { GetAttemptUseCase } from '../application/get-attempt.use-case.js';
import type { SaveAnswersUseCase, SaveAnswerItem } from '../application/save-answers.use-case.js';
import type { SubmitAttemptUseCase } from '../application/submit-attempt.use-case.js';
import type { GetStudentResultUseCase } from '../application/get-student-result.use-case.js';
import type { RecordEventUseCase } from '../application/record-event.use-case.js';
import type { SaveRecordingUseCase } from '../application/save-recording.use-case.js';
import { requireUser } from './request-user.js';

export class ExamStudentController {
  constructor(
    private readonly listAvailable: ListAvailableExamsUseCase,
    private readonly startAttempt: StartAttemptUseCase,
    private readonly getAttempt: GetAttemptUseCase,
    private readonly saveAnswers: SaveAnswersUseCase,
    private readonly submitAttempt: SubmitAttemptUseCase,
    private readonly getResult: GetStudentResultUseCase,
    private readonly recordEvent: RecordEventUseCase,
    private readonly saveRecording: SaveRecordingUseCase,
  ) {}

  public listAvailableExams = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const exams = await this.listAvailable.execute({ studentId: user.id });
      res.status(200).json({ data: exams });
    } catch (error) {
      next(error);
    }
  };

  public start = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const result = await this.startAttempt.execute({ studentId: user.id, examId });
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  };

  public currentAttempt = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const result = await this.getAttempt.execute({ studentId: user.id, examId });
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  };

  public save = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const body = req.body as { answers: SaveAnswerItem[] };
      const result = await this.saveAnswers.execute({
        studentId: user.id,
        examId,
        answers: body.answers,
      });
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  };

  public submit = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const result = await this.submitAttempt.execute({ studentId: user.id, examId });
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  };

  public result = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const result = await this.getResult.execute({
        studentId: user.id,
        examId,
        requesterRole: user.role,
      });
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  };

  public reportEvent = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const body = req.body as {
        type: ExamEventType;
        durationMs?: number | null;
        source?: string;
        clientOccurredAt?: string | null;
        metadata?: Record<string, unknown>;
      };
      const result = await this.recordEvent.execute({
        studentId: user.id,
        examId,
        type: body.type,
        durationMs: body.durationMs ?? null,
        source: body.source,
        clientOccurredAt: body.clientOccurredAt ?? null,
        metadata: body.metadata,
      });
      res.status(201).json({ data: result });
    } catch (error) {
      next(error);
    }
  };

  public uploadRecording = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const file = req.file;
      if (!file) {
        throw new Error('Missing file after upload middleware');
      }
      const body = req.body as {
        eventId?: string;
        durationMs?: number;
        kind?: string;
      };
      const result = await this.saveRecording.execute({
        studentId: user.id,
        examId,
        eventId: body.eventId ?? null,
        durationMs: body.durationMs ?? null,
        kind: body.kind,
        mimeType: file.mimetype,
        data: file.buffer,
      });
      res.status(201).json({ data: result });
    } catch (error) {
      next(error);
    }
  };
}
