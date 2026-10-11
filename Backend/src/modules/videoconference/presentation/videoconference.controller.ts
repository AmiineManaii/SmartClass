import type { Request, Response, NextFunction } from 'express';
import type { GetTimetableWeekUseCase } from '../application/get-timetable-week.use-case.js';
import { validatedQuery } from '../../../shared/http/validate.middleware.js';

interface TimetableValidatedQuery {
  classGroupId: string;
  weekStart?: string;
}

export class VideoconferenceController {
  constructor(private readonly getTimetableWeekUseCase: GetTimetableWeekUseCase) {}

  public getTimetable = async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const query = validatedQuery<TimetableValidatedQuery>(req);
      const result = await this.getTimetableWeekUseCase.execute(
        query.classGroupId,
        query.weekStart ? new Date(`${query.weekStart}T00:00:00.000Z`) : undefined,
      );
      res.status(200).json({
        data: result.week,
      });
    } catch (err) {
      next(err);
    }
  };
}
