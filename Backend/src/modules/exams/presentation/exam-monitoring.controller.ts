import type { Request, Response, NextFunction } from 'express';
import { NotFoundError } from '../../../shared/errors/app-error.js';
import {
  parseHttpRangeHeader,
  type StoragePort,
} from '../../../shared/storage/storage.port.js';
import type { GetAttemptMonitoringUseCase } from '../application/get-attempt-monitoring.use-case.js';
import type { UpdateEventStateUseCase } from '../application/update-event-state.use-case.js';
import type { ResolveRecordingUseCase } from '../application/resolve-recording.use-case.js';
import type { DeleteRecordingUseCase } from '../application/delete-recording.use-case.js';
import { requireUser } from './request-user.js';

export class ExamMonitoringController {
  constructor(
    private readonly getAttemptMonitoring: GetAttemptMonitoringUseCase,
    private readonly updateEventState: UpdateEventStateUseCase,
    private readonly resolveRecording: ResolveRecordingUseCase,
    private readonly deleteRecording: DeleteRecordingUseCase,
    private readonly storage: StoragePort,
  ) {}

  public attempt = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId, attemptId } = req.params as { examId: string; attemptId: string };
      const result = await this.getAttemptMonitoring.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
        attemptId,
      });
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  };

  public setEventState = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId, eventId } = req.params as { examId: string; eventId: string };
      const body = req.body as { state: 'NEW' | 'REVIEWED' | 'CONFIRMED' };
      const event = await this.updateEventState.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
        eventId,
        state: body.state,
      });
      res.status(200).json({ data: event });
    } catch (error) {
      next(error);
    }
  };

  public streamRecording = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId, recordingId } = req.params as { examId: string; recordingId: string };
      const resolved = await this.resolveRecording.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
        recordingId,
      });
      const stat = await this.storage.stat(resolved.storageKey);
      if (!stat || stat.sizeBytes === 0) {
        throw new NotFoundError('Recording file is missing from storage');
      }

      const rangeHeader = req.headers.range;
      if (rangeHeader) {
        const range = parseHttpRangeHeader(rangeHeader, stat.sizeBytes);
        if (!range) {
          res.setHeader('Content-Range', `bytes */${stat.sizeBytes}`);
          res.status(416).end();
          return;
        }
        res.status(206);
        res.setHeader('Content-Range', `bytes ${range.start}-${range.end}/${stat.sizeBytes}`);
        res.setHeader('Accept-Ranges', 'bytes');
        res.setHeader('Content-Length', String(range.end - range.start + 1));
        res.setHeader('Content-Type', resolved.mimeType);
        res.setHeader('Cache-Control', 'private, no-store');
        const stream = await this.storage.createReadStream(resolved.storageKey, range);
        stream.on('error', (error: unknown) => next(error));
        stream.pipe(res);
        return;
      }

      res.status(200);
      res.setHeader('Accept-Ranges', 'bytes');
      res.setHeader('Content-Length', String(stat.sizeBytes));
      res.setHeader('Content-Type', resolved.mimeType);
      res.setHeader('Cache-Control', 'private, no-store');
      const stream = await this.storage.createReadStream(resolved.storageKey);
      stream.on('error', (error: unknown) => next(error));
      stream.pipe(res);
    } catch (error) {
      next(error);
    }
  };

  public removeRecording = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId, recordingId } = req.params as { examId: string; recordingId: string };
      const result = await this.deleteRecording.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
        recordingId,
      });
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  };
}
