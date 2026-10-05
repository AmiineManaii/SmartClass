import type { Request, Response, NextFunction } from 'express';
import type { GetLivenessUseCase } from '../application/get-liveness.use-case.js';
import type { GetReadinessUseCase } from '../application/get-readiness.use-case.js';

export class HealthController {
  constructor(
    private readonly getLivenessUseCase: GetLivenessUseCase,
    private readonly getReadinessUseCase: GetReadinessUseCase,
  ) {}

  public getLive = (_req: Request, res: Response): void => {
    const result = this.getLivenessUseCase.execute();
    res.status(200).json(result);
  };

  public getReady = async (_req: Request, res: Response, next: NextFunction): Promise<void> => {
    try {
      const result = await this.getReadinessUseCase.execute();
      res.status(200).json(result);
    } catch (err) {
      next(err);
    }
  };
}
