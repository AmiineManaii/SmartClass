import type { Request, Response, NextFunction } from 'express';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { DeleteCourseUseCase } from '../application/delete-course.use-case.js';
import type { GetCourseUseCase } from '../application/get-course.use-case.js';
import type { ListMyCoursesUseCase } from '../application/list-my-courses.use-case.js';
import type { ListPublishedCoursesUseCase } from '../application/list-published-courses.use-case.js';
import type { PublishCourseUseCase } from '../application/publish-course.use-case.js';
import type { SaveCourseUseCase } from '../application/save-course.use-case.js';
import type { UnpublishCourseUseCase } from '../application/unpublish-course.use-case.js';

const requireUser = (req: Request): { id: string; role: Role | null } => {
  if (!req.user) {
    throw new UnauthorizedError('Authentication required');
  }
  return { id: req.user.id, role: req.user.role };
};

export class CoursesController {
  constructor(
    private readonly saveCourseUseCase: SaveCourseUseCase,
    private readonly listMyCoursesUseCase: ListMyCoursesUseCase,
    private readonly listPublishedCoursesUseCase: ListPublishedCoursesUseCase,
    private readonly getCourseUseCase: GetCourseUseCase,
    private readonly publishCourseUseCase: PublishCourseUseCase,
    private readonly unpublishCourseUseCase: UnpublishCourseUseCase,
    private readonly deleteCourseUseCase: DeleteCourseUseCase,
  ) {}

  public saveCourse = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const body = req.body as {
        title: string;
        subject?: string;
        content: string;
        level: 'concis' | 'equilibre' | 'detaille';
        difficulty?: 'facile' | 'moyen' | 'difficile';
        format?: 'resume' | 'flashcards' | 'carte-mentale';
      };
      const result = await this.saveCourseUseCase.execute({
        requesterId: user.id,
        title: body.title,
        subject: body.subject ?? null,
        content: body.content,
        level: body.level,
        difficulty: body.difficulty,
        format: body.format,
      });
      res.status(201).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public listMyCourses = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const result = await this.listMyCoursesUseCase.execute(user.id);
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public listPublishedCourses = async (
    _req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.listPublishedCoursesUseCase.execute();
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public getCourse = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const result = await this.getCourseUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public publishCourse = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const result = await this.publishCourseUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public unpublishCourse = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const result = await this.unpublishCourseUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public deleteCourse = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const result = await this.deleteCourseUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };
}
