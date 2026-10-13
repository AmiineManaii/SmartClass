import type { Request, Response, NextFunction } from 'express';
import type { GetTimetableWeekUseCase } from '../application/get-timetable-week.use-case.js';
import { UnauthorizedError } from '../../../shared/errors/app-error.js';
import { ErrorCodes } from '../../../shared/errors/error-codes.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';

interface TimetableValidatedQuery {
  classGroupId: string;
  weekStart?: string;
}

export class VideoconferenceController {
  constructor(private readonly getTimetableWeekUseCase: GetTimetableWeekUseCase) {}

  public getTimetable = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      if (!req.user) {
        throw new UnauthorizedError('Unauthorized access', ErrorCodes.AUTH_TOKEN_INVALID);
      }
      const query = validatedQuery<TimetableValidatedQuery>(req);
      const result = await this.getTimetableWeekUseCase.execute(
        query.classGroupId,
        query.weekStart ? new Date(`${query.weekStart}T00:00:00.000Z`) : undefined,
        { id: req.user.id, role: req.user.role },
      );
      res.status(200).json({
        data: result.week,
      });
    } catch (err) {
      next(err);
    }
  };
}
