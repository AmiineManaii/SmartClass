import type { Request, Response, NextFunction } from 'express';
import type {
  GenerateCourseDTO,
  GenerateCourseUseCase,
} from '../application/generate-course.use-case.js';
import type { GenerateOutlineUseCase } from '../application/generate-outline.use-case.js';
import type { RefineSectionUseCase } from '../application/refine-section.use-case.js';
import type { GetAiStatusUseCase } from '../application/get-ai-status.use-case.js';
import type { ImprovePdfUseCase } from '../application/improve-pdf.use-case.js';
import type {
  GenerateDifficulty,
  GenerateFormat,
  GenerateLevel,
} from '../domain/ai-gateway.port.js';
import { AppError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import { ValidationError } from '../../../shared/errors/app-error.js';
import { improvePdfFieldsSchema } from './ai.validation.js';

export class AiController {
  constructor(
    private readonly generateCourseUseCase: GenerateCourseUseCase,
    private readonly improvePdfUseCase: ImprovePdfUseCase,
    private readonly getAiStatusUseCase: GetAiStatusUseCase,
    private readonly generateOutlineUseCase: GenerateOutlineUseCase,
    private readonly refineSectionUseCase: RefineSectionUseCase,
  ) {}

  public generateOutline = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.generateOutlineUseCase.execute(req.body);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public refineSection = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.refineSectionUseCase.execute(req.body);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public generateCourse = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.generateCourseUseCase.execute(req.body);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  /// Dedicated per-method endpoints (simpler payloads for the teacher UI).
  public fromTopic = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const body = req.body as Partial<GenerateCourseDTO>;
      const result = await this.generateCourseUseCase.execute({
        level: 'equilibre',
        format: 'resume',
        ...body,
        mode: 'topic',
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public fromUrl = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const body = req.body as Partial<GenerateCourseDTO>;
      const result = await this.generateCourseUseCase.execute({
        level: 'equilibre',
        format: 'resume',
        ...body,
        mode: 'url',
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public improvePdf = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      // ZodError is not mapped by the central handler: convert to a stable 422.
      const parsed = improvePdfFieldsSchema.safeParse(req.body);
      if (!parsed.success) {
        throw new ValidationError(
          'Validation failed',
          parsed.error.errors.map((issue) => ({
            path: issue.path.join('.'),
            message: issue.message,
          })),
        );
      }
      const file = req.file as Express.Multer.File;
      const result = await this.improvePdfUseCase.execute({
        file: {
          buffer: file.buffer,
          originalName: file.originalname,
          size: file.size,
        },
        level: parsed.data.level as GenerateLevel,
        difficulty: parsed.data.difficulty as GenerateDifficulty,
        extras: parsed.data.extras,
        format: parsed.data.format as GenerateFormat,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public getStatus = async (
    _req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.getAiStatusUseCase.execute();
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  /**
   * Live progress streaming (SSE). Headers go out first, then every
   * outcome is an event: `{"delta"}` chunks, a final `{"done":true,...meta}`,
   * or `{"error":{"code","message"}}` (validation, gateway down, overload).
   * An SSE `: ping` comment is sent every 10 s while the model is silent
   * (tool execution before the first token) so clients and proxies never
   * treat the stream as idle. The client must handle the error event —
   * HTTP stays 200.
   */
  public streamGenerate = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    this.streamCourse(req, res, next, (onDelta) =>
      this.generateCourseUseCase.stream(req.body as GenerateCourseDTO, onDelta),
    );
  };

  public streamImprovePdf = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    const parsed = improvePdfFieldsSchema.safeParse(req.body);
    if (!parsed.success) {
      next(
        new ValidationError(
          'Validation failed',
          parsed.error.errors.map((issue) => ({
            path: issue.path.join('.'),
            message: issue.message,
          })),
        ),
      );
      return;
    }
    const file = req.file as Express.Multer.File;
    this.streamCourse(
      req,
      res,
      next,
      // Extraction happens inside the use-case: report it before the
      // model starts so clients can tell a long PDF parse apart from
      // model silence (`extracting` → `generating` → deltas).
      (onDelta, onPhase) =>
        this.improvePdfUseCase.stream(
          {
            file: {
              buffer: file.buffer,
              originalName: file.originalname,
              size: file.size,
            },
            level: parsed.data.level as GenerateLevel,
            difficulty: parsed.data.difficulty as GenerateDifficulty,
            extras: parsed.data.extras,
            format: parsed.data.format as GenerateFormat,
          },
          onDelta,
          onPhase,
        ),
      { initialPhase: 'extracting' },
    );
  };;

  private streamCourse(
    req: Request,
    res: Response,
    next: NextFunction,
    run: (
      onDelta: (delta: string) => void,
      onPhase: (phase: string) => void,
    ) => Promise<Record<string, unknown>>,
    opts?: { initialPhase?: string },
  ): void {
    res.writeHead(200, {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    });
    const send = (payload: unknown): void => {
      res.write(`data: ${JSON.stringify(payload)}\n\n`);
    };
    let closed = false;
    // Phase events (`{"phase": ...}`) narrate silent pipeline steps
    // (PDF extraction) before the first text delta arrives.
    const sendPhase = (phase: string): void => {
      if (!closed) send({ phase });
    };
    // SSE comment heartbeat: the local LLM can stay silent for 20 s+
    // before the first token (server-side tool execution). A byte every
    // 10 s keeps mobile radios, proxies and the app's receive timeout
    // from killing the idle stream. Clients ignore `:` comment lines.
    const heartbeat = setInterval(() => {
      if (!closed) res.write(': ping\n\n');
    }, 10_000);
    const finish = (): void => {
      clearInterval(heartbeat);
    };
    req.on('close', () => {
      closed = true;
      finish();
    });
    if (opts?.initialPhase) sendPhase(opts.initialPhase);
    run(
      (delta: string) => {
        if (!closed) send({ delta });
      },
      sendPhase,
    ).then(
      (meta) => {
        finish();
        if (!closed) {
          send({ done: true, ...meta });
          res.end();
        }
      },
      (error: unknown) => {
        finish();
        if (closed) return;
        if (error instanceof AppError) {
          send({ error: { code: error.code, message: error.message } });
        } else {
          send({ error: { code: ErrorCodes.INTERNAL_ERROR, message: 'Internal server error' } });
        }
        res.end();
      },
    ).catch(next);
  }
}
