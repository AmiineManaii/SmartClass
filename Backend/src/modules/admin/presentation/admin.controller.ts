import type { Request, Response, NextFunction } from 'express';
import type { GetOverviewUseCase } from '../application/get-overview.use-case.js';

export class AdminController {
  constructor(private readonly getOverviewUseCase: GetOverviewUseCase) {}

  public getOverview = async (
    _req: Request,
    res: Response,
    next: NextFunction,
  ): Promise<void> => {
    try {
      const result = await this.getOverviewUseCase.execute();
      res.status(200).json({
        data: result.overview,
      });
    } catch (err) {
      next(err);
    }
  };
}
