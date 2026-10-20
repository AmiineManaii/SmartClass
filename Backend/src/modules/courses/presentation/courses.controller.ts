import type { Request, Response, NextFunction } from 'express';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { DeleteCourseUseCase } from '../application/delete-course.use-case.js';
import type { GetCourseUseCase } from '../application/get-course.use-case.js';
import type { ListMyCoursesUseCase } from '../application/list-my-courses.use-case.js';
import type { ListPublishedCoursesUseCase } from '../application/list-published-courses.use-case.js';
import type { PublishCourseUseCase } from '../application/publish-course.use-case.js';
import type { SaveCourseUseCase } from '../application/save-course.use-case.js';
import type { UpdateCourseUseCase } from '../application/update-course.use-case.js';
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
    private readonly updateCourseUseCase: UpdateCourseUseCase,
    private readonly listMyCoursesUseCase: ListMyCoursesUseCase,
    private readonly listPublishedCoursesUseCase: ListPublishedCoursesUseCase,
    private readonly getCourseUseCase: GetCourseUseCase,
    private readonly publishCourseUseCase: PublishCourseUseCase,
    private readonly unpublishCourseUseCase: UnpublishCourseUseCase,
    private readonly deleteCourseUseCase: DeleteCourseUseCase,
  ) {}

  public updateCourse = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const result = await this.updateCourseUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
        ...req.body,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

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
        classGroupIds?: string[];
        outline?: Parameters<SaveCourseUseCase['execute']>[0]['outline'];
      };
      const result = await this.saveCourseUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        title: body.title,
        subject: body.subject ?? null,
        content: body.content,
        level: body.level,
        difficulty: body.difficulty,
        format: body.format,
        classGroupIds: body.classGroupIds,
        outline: body.outline ?? null,
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
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.listPublishedCoursesUseCase.execute(
        req.user?.id,
        req.user?.role,
      );
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
