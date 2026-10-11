import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import type { FraudRepositoryPort } from './domain/fraud-repository.port.js';
import { PrismaFraudRepositoryAdapter } from './infrastructure/prisma-fraud-repository.adapter.js';
import { ListFraudReportsUseCase } from './application/list-fraud-reports.use-case.js';
import { GetFraudSummaryUseCase } from './application/get-fraud-summary.use-case.js';
import { UpdateFraudReportUseCase } from './application/update-fraud-report.use-case.js';
import { ExamsController } from './presentation/exams.controller.js';
import { createExamsRouter } from './presentation/exams.routes.js';

export interface ExamsModuleOptions {
  fraudRepository?: FraudRepositoryPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireAdminMiddleware?: RequestHandler;
}

export interface ExamsModule {
  router: Router;
  controller: ExamsController;
}

export const createExamsModule = (options: ExamsModuleOptions = {}): ExamsModule => {
  const fraudRepository = options.fraudRepository ?? new PrismaFraudRepositoryAdapter();

  const listFraudReportsUseCase = new ListFraudReportsUseCase(fraudRepository);
  const getFraudSummaryUseCase = new GetFraudSummaryUseCase(fraudRepository);
  const updateFraudReportUseCase = new UpdateFraudReportUseCase(fraudRepository);

  const controller = new ExamsController(
    listFraudReportsUseCase,
    getFraudSummaryUseCase,
    updateFraudReportUseCase,
  );

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('ExamsModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireAdminMiddleware =
    options.requireAdminMiddleware ?? createRequireRoleMiddleware(['ADMIN'] as Role[]);

  const router = createExamsRouter({
    controller,
    authenticateMiddleware,
    requireAdminMiddleware,
  });

  return { router, controller };
};
