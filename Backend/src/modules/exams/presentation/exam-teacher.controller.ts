import type { Request, Response, NextFunction } from 'express';
import type { ExamSettings, ExamSource } from '../domain/exam.entity.js';
import type { CreateExamUseCase } from '../application/create-exam.use-case.js';
import type { UpdateExamUseCase } from '../application/update-exam.use-case.js';
import type { ListMyExamsUseCase } from '../application/list-my-exams.use-case.js';
import type { GetTeacherExamUseCase } from '../application/get-teacher-exam.use-case.js';
import type { PublishExamUseCase } from '../application/publish-exam.use-case.js';
import type { CloseExamUseCase } from '../application/close-exam.use-case.js';
import type { ImportExamUseCase } from '../application/import-exam.use-case.js';
import type { GenerateExamAiUseCase } from '../application/generate-exam-ai.use-case.js';
import type { ListClassCoursesUseCase } from '../application/list-class-courses.use-case.js';
import type { GetExamResultsUseCase } from '../application/get-exam-results.use-case.js';
import { requireUser } from './request-user.js';

export class ExamTeacherController {
  constructor(
    private readonly createExam: CreateExamUseCase,
    private readonly updateExam: UpdateExamUseCase,
    private readonly listMyExams: ListMyExamsUseCase,
    private readonly getExam: GetTeacherExamUseCase,
    private readonly publishExam: PublishExamUseCase,
    private readonly closeExam: CloseExamUseCase,
    private readonly importExam: ImportExamUseCase,
    private readonly generateExamAi: GenerateExamAiUseCase,
    private readonly listClassCourses: ListClassCoursesUseCase,
    private readonly getResults: GetExamResultsUseCase,
  ) {}

  public create = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const body = req.body as {
        title: string;
        description?: string | null;
        classGroupId: string;
        durationMinutes: number;
        startsAt: Date;
        endsAt: Date;
        source?: ExamSource;
        settings?: Partial<ExamSettings>;
        questions: unknown[];
      };
      const exam = await this.createExam.execute({
        requesterId: user.id,
        requesterRole: user.role,
        title: body.title,
        description: body.description ?? null,
        classGroupId: body.classGroupId,
        durationMinutes: body.durationMinutes,
        startsAt: body.startsAt,
        endsAt: body.endsAt,
        source: body.source,
        settings: body.settings,
        questions: body.questions,
      });
      res.status(201).json({ data: exam });
    } catch (error) {
      next(error);
    }
  };

  public update = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const body = req.body as {
        title?: string;
        description?: string | null;
        durationMinutes?: number;
        startsAt?: Date;
        endsAt?: Date;
        settings?: Partial<ExamSettings>;
        questions?: unknown[];
      };
      const exam = await this.updateExam.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
        ...body,
      });
      res.status(200).json({ data: exam });
    } catch (error) {
      next(error);
    }
  };

  public listMine = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const exams = await this.listMyExams.execute({
        requesterId: user.id,
        requesterRole: user.role,
      });
      res.status(200).json({ data: exams });
    } catch (error) {
      next(error);
    }
  };

  public getOne = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const exam = await this.getExam.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
      });
      res.status(200).json({ data: exam });
    } catch (error) {
      next(error);
    }
  };

  public publish = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const exam = await this.publishExam.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
      });
      res.status(200).json({ data: exam });
    } catch (error) {
      next(error);
    }
  };

  public close = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const result = await this.closeExam.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
      });
      res.status(200).json({ data: result });
    } catch (error) {
      next(error);
    }
  };

  public importPreview = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      requireUser(req);
      const file = req.file;
      if (!file) {
        throw new Error('Missing file after upload middleware');
      }
      const preview = this.importExam.execute({
        originalname: file.originalname,
        mimetype: file.mimetype,
        buffer: file.buffer,
      });
      res.status(200).json({ data: preview });
    } catch (error) {
      next(error);
    }
  };

  public classCourses = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const { classGroupId } = req.params as { classGroupId: string };
      const courses = await this.listClassCourses.execute({
        requesterId: user.id,
        requesterRole: user.role,
        classGroupId,
      });
      res.status(200).json({ data: courses });
    } catch (error) {
      next(error);
    }
  };

  public generateAi = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const body = req.body as {
        classGroupId: string;
        courseIds?: string[];
        title?: string;
        difficulty?: 'facile' | 'moyen' | 'difficile';
        questionCount?: number;
      };
      const preview = await this.generateExamAi.execute({
        requesterId: user.id,
        requesterRole: user.role,
        ...body,
      });
      res.status(200).json({ data: preview });
    } catch (error) {
      next(error);
    }
  };

  public results = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const user = requireUser(req);
      const { examId } = req.params as { examId: string };
      const results = await this.getResults.execute({
        requesterId: user.id,
        requesterRole: user.role,
        examId,
      });
      res.status(200).json({ data: results });
    } catch (error) {
      next(error);
    }
  };
}
