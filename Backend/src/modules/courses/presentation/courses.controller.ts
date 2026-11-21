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
import type {
  DeleteCourseStudyArtifactUseCase,
  GetCourseStudyWorkspaceUseCase,
} from '../application/course-study.use-cases.js';
import type { GenerateCourseStudyArtifactUseCase } from '../application/generate-course-study-artifact.use-case.js';
import type { AskCourseTutorUseCase } from '../application/ask-course-tutor.use-case.js';

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
    private readonly getCourseStudyUseCase: GetCourseStudyWorkspaceUseCase,
    private readonly generateCourseStudyArtifactUseCase: GenerateCourseStudyArtifactUseCase,
    private readonly deleteCourseStudyArtifactUseCase: DeleteCourseStudyArtifactUseCase,
    private readonly askCourseTutorUseCase: AskCourseTutorUseCase,
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

  public getCourseStudy = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const result = await this.getCourseStudyUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
      });
      res.status(200).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public generateCourseStudyArtifact = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const body = req.body as {
        kind: 'SUMMARY' | 'FLASHCARDS';
        language?: 'fr' | 'en';
        summaryMode?: Parameters<
          GenerateCourseStudyArtifactUseCase['execute']
        >[0]['artifact']['summaryMode'];
        flashcardCount?: number;
        focus?: string;
      };
      const result = await this.generateCourseStudyArtifactUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
        artifact: {
          kind: body.kind,
          language: body.language,
          summaryMode: body.summaryMode,
          flashcardCount: body.flashcardCount,
          focus: body.focus,
        },
      });
      res.status(201).json({ data: result });
    } catch (err) {
      next(err);
    }
  };

  public deleteCourseStudyArtifact = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      await this.deleteCourseStudyArtifactUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
        artifactId: req.params.artifactId as string,
      });
      res.status(204).send();
    } catch (err) {
      next(err);
    }
  };

  public askCourseTutor = async (
    req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const user = requireUser(req);
      const body = req.body as {
        question: string;
        conversationId?: string;
        language?: 'fr' | 'en';
      };
      const result = await this.askCourseTutorUseCase.execute({
        requesterId: user.id,
        requesterRole: user.role,
        courseId: req.params.id as string,
        question: body.question,
        conversationId: body.conversationId,
        language: body.language,
      });
      res.status(201).json({ data: result });
    } catch (err) {
      next(err);
    }
  };
}
