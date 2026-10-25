import type { Request, Response, NextFunction } from 'express';
import type {
  GenerateCourseDTO,
  GenerateCourseUseCase,
} from '../application/generate-course.use-case.js';
import type { GenerateOutlineUseCase } from '../application/generate-outline.use-case.js';
import type { RefineSectionUseCase } from '../application/refine-section.use-case.js';
import type { GetAiStatusUseCase } from '../application/get-ai-status.use-case.js';
import type { ImprovePdfUseCase } from '../application/improve-pdf.use-case.js';
import type { GetCourseBuildUseCase } from '../application/get-course-build.use-case.js';
import type {
  GenerateSectionDTO,
  GenerateSectionUseCase,
} from '../application/generate-section.use-case.js';
import type { ValidateSectionUseCase } from '../application/validate-section.use-case.js';
import type { GenerateSectionImageUseCase } from '../application/generate-section-image.use-case.js';
import type { SearchSectionImagesUseCase } from '../application/search-section-images.use-case.js';
import type { ApplySectionImageUseCase } from '../application/apply-section-image.use-case.js';
import type { SectionImageJobService } from '../application/section-image-job.service.js';
import type { PdfTextExtractorPort } from '../infrastructure/pdf-text-extractor.adapter.js';
import type {
  GenerateDifficulty,
  GenerateFormat,
  GenerateLevel,
} from '../domain/ai-gateway.port.js';
import { AppError, UnauthorizedError, ValidationError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import {
  applySectionImageBodySchema,
  courseBuildParamsSchema,
  generateOutlineBodySchema,
  generateSectionBodySchema,
  imageSectionBodySchema,
  improvePdfFieldsSchema,
  searchSectionImagesBodySchema,
  sectionImageJobParamsSchema,
  validateSectionBodySchema,
} from './ai.validation.js';
import type { Role } from '../../auth/index.js';

const toPublicImageJob = (job: {
  id: string;
  courseId: string;
  sectionKey: string;
  kind: string;
  status: string;
  createdAt: Date;
  updatedAt: Date;
  result?: unknown;
  error?: unknown;
}) => ({
  id: job.id,
  courseId: job.courseId,
  sectionKey: job.sectionKey,
  kind: job.kind,
  status: job.status,
  createdAt: job.createdAt,
  updatedAt: job.updatedAt,
  ...(job.result ? { result: job.result } : {}),
  ...(job.error ? { error: job.error } : {}),
});

const requireUser = (req: Request): { id: string; role: Role | null } => {
  if (!req.user) {
    throw new UnauthorizedError('Authentication required');
  }
  return { id: req.user.id, role: req.user.role };
};

/** Stable 422 from a Zod failure (ZodError is not mapped centrally). */
const toValidationError = (error: {
  errors: { path: (string | number)[]; message: string }[];
}): ValidationError =>
  new ValidationError(
    'Validation failed',
    error.errors.map((issue) => ({ path: issue.path.join('.'), message: issue.message })),
  );

export class AiController {
  constructor(
    private readonly generateCourseUseCase: GenerateCourseUseCase,
    private readonly improvePdfUseCase: ImprovePdfUseCase,
    private readonly getAiStatusUseCase: GetAiStatusUseCase,
    private readonly generateOutlineUseCase: GenerateOutlineUseCase,
    private readonly refineSectionUseCase: RefineSectionUseCase,
    private readonly getCourseBuildUseCase: GetCourseBuildUseCase,
    private readonly generateSectionUseCase: GenerateSectionUseCase,
    private readonly validateSectionUseCase: ValidateSectionUseCase,
    private readonly generateSectionImageUseCase: GenerateSectionImageUseCase,
    private readonly searchSectionImagesUseCase: SearchSectionImagesUseCase,
    private readonly applySectionImageUseCase: ApplySectionImageUseCase,
    private readonly sectionImageJobService: SectionImageJobService,
    private readonly pdfExtractor?: PdfTextExtractorPort,
  ) {}

  public generateOutline = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const body = { ...req.body };
      if (req.file && this.pdfExtractor) {
        try {
          const { text } = await this.pdfExtractor.extract(req.file.buffer);
          body.sourceContext = text.slice(0, 50000);
          if (!body.topic && !body.subject) {
            body.topic = req.file.originalname
              .replace(/\.[^/.]+$/, '')
              .replace(/[_-]+/g, ' ')
              .trim();
          }
        } catch {
          if (!body.topic && !body.subject) {
            body.topic = req.file.originalname
              .replace(/\.[^/.]+$/, '')
              .replace(/[_-]+/g, ' ')
              .trim();
          }
        }
      }
      const parsed = generateOutlineBodySchema.safeParse(body);
      if (!parsed.success) {
        throw toValidationError(parsed.error);
      }
      const result = await this.generateOutlineUseCase.execute(parsed.data);
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public refineSection = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const result = await this.refineSectionUseCase.execute({
        ...req.body,
        requesterId: user.id,
        requesterRole: user.role,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  /** GET /courses/:id/build — course metadata + ordered sections. */
  public getCourseBuild = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const params = courseBuildParamsSchema.safeParse(req.params);
      if (!params.success) throw toValidationError(params.error);
      const user = requireUser(req);
      const result = await this.getCourseBuildUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: params.data.id,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  /** POST /courses/sections/generate — SSE stream of one section. */
  public streamGenerateSection = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    this.runSectionStream(req, res, next, false);
  };

  /** POST /courses/sections/regenerate — overwrites a VALIDATED section. */
  public streamRegenerateSection = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    this.runSectionStream(req, res, next, true);
  };

  /** POST /courses/sections/validate — teacher approves one section. */
  public validateSection = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const parsed = validateSectionBodySchema.safeParse(req.body);
      if (!parsed.success) throw toValidationError(parsed.error);
      const user = requireUser(req);
      const result = await this.validateSectionUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: parsed.data.courseId,
        sectionKey: parsed.data.sectionKey,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  /**
   * POST /courses/sections/image — local ComfyUI illustration for one
   * section. When ComfyUI is unconfigured/unreachable the adapter answers
   * 503 IMAGE_SERVICE_UNAVAILABLE; the web-image alternative stays usable.
   */
  public generateSectionImage = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const parsed = imageSectionBodySchema.safeParse(req.body);
      if (!parsed.success) throw toValidationError(parsed.error);
      const user = requireUser(req);
      const result = await this.generateSectionImageUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: parsed.data.courseId,
        sectionKey: parsed.data.sectionKey,
        kind: parsed.data.kind,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  /** POST /courses/sections/image/jobs — start a ComfyUI job (202). */
  public startSectionImageJob = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const parsed = imageSectionBodySchema.safeParse(req.body);
      if (!parsed.success) throw toValidationError(parsed.error);
      const user = requireUser(req);
      const job = await this.sectionImageJobService.start({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: parsed.data.courseId,
        sectionKey: parsed.data.sectionKey,
        kind: parsed.data.kind,
      });
      res.status(202).json({ data: toPublicImageJob(job) });
    } catch (err) {
      next(err);
    }
  };

  /** GET /courses/sections/image/jobs/:jobId — poll one job. */
  public getSectionImageJob = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const parsed = sectionImageJobParamsSchema.safeParse(req.params);
      if (!parsed.success) throw toValidationError(parsed.error);
      const user = requireUser(req);
      const job = await this.sectionImageJobService.get({
        requesterId: user.id,
        requesterRole: user.role,
        jobId: parsed.data.jobId,
      });
      res.status(200).json({ data: toPublicImageJob(job) });
    } catch (err) {
      next(err);
    }
  };

  /** POST /courses/sections/image/search — up to five web candidates. */
  public searchSectionImages = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const parsed = searchSectionImagesBodySchema.safeParse(req.body);
      if (!parsed.success) throw toValidationError(parsed.error);
      const user = requireUser(req);
      const result = await this.searchSectionImagesUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: parsed.data.courseId,
        sectionKey: parsed.data.sectionKey,
        query: parsed.data.query,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  /** POST /courses/sections/image/apply — insert the chosen image. */
  public applySectionImage = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const parsed = applySectionImageBodySchema.safeParse(req.body);
      if (!parsed.success) throw toValidationError(parsed.error);
      const user = requireUser(req);
      const result = await this.applySectionImageUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: parsed.data.courseId,
        sectionKey: parsed.data.sectionKey,
        imageUrl: parsed.data.imageUrl,
        caption: parsed.data.caption,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  private runSectionStream(
    req: Request,
    res: Response,
    next: NextFunction,
    regenerate: boolean,
  ): void {
    const parsed = generateSectionBodySchema.safeParse(req.body);
    if (!parsed.success) {
      next(toValidationError(parsed.error));
      return;
    }
    let user: { id: string; role: Role | null };
    try {
      user = requireUser(req);
    } catch (err) {
      next(err);
      return;
    }
    const dto: GenerateSectionDTO = {
      requesterId: user.id,
      requesterRole: user.role,
      courseId: parsed.data.courseId,
      sectionKey: parsed.data.sectionKey,
      regenerate,
      level: parsed.data.level,
      difficulty: parsed.data.difficulty,
      extras: parsed.data.extras,
    };
    this.streamCourse(
      req,
      res,
      next,
      (onDelta, onPhase) => this.generateSectionUseCase.stream(dto, onDelta, onPhase),
      { initialPhase: 'memory' },
    );
  }

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
  public fromTopic = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
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

  public fromUrl = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
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

  public improvePdf = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
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
        outline: parsed.data.outline,
      });
      res.status(200).json({
        data: result,
      });
    } catch (err) {
      next(err);
    }
  };

  public getStatus = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
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
            outline: parsed.data.outline,
          },
          onDelta,
          onPhase,
        ),
      { initialPhase: 'extracting' },
    );
  };

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
    run((delta: string) => {
      if (!closed) send({ delta });
    }, sendPhase)
      .then(
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
      )
      .catch(next);
  }
}
