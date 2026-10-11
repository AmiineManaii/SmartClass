import { Router, type RequestHandler } from 'express';
import type { ExamsController } from './exams.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  fraudReportIdParamsSchema,
  listFraudReportsQuerySchema,
  updateFraudReportBodySchema,
} from './exams.validation.js';

export interface ExamsRouterOptions {
  controller: ExamsController;
  authenticateMiddleware: RequestHandler;
  requireAdminMiddleware: RequestHandler;
}

export const createExamsRouter = (options: ExamsRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireAdminMiddleware } = options;

  router.use(authenticateMiddleware, requireAdminMiddleware);

  router.get('/fraud-reports/summary', controller.getFraudSummary);

  router.get(
    '/fraud-reports',
    validate({ query: listFraudReportsQuerySchema }),
    controller.listFraudReports,
  );

  router.patch(
    '/fraud-reports/:id',
    validate({ params: fraudReportIdParamsSchema, body: updateFraudReportBodySchema }),
    controller.updateFraudReport,
  );

  return router;
};
