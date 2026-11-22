import { Router, type RequestHandler } from 'express';
import { validate } from '../../../shared/http/validate.middleware.js';
import type { KnowledgeController } from './knowledge.controller.js';
import {
  documentIdParamsSchema,
  listKnowledgeDocumentsQuerySchema,
  reindexKnowledgeSchema,
  searchKnowledgeSchema,
} from './knowledge.validation.js';

export interface KnowledgeRouterOptions {
  controller: KnowledgeController;
  authenticateMiddleware: RequestHandler;
  requireTeacherMiddleware: RequestHandler;
}

export const createKnowledgeRouter = (options: KnowledgeRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireTeacherMiddleware } = options;

  router.post(
    '/search',
    authenticateMiddleware,
    validate({ body: searchKnowledgeSchema }),
    controller.search,
  );

  router.get(
    '/documents',
    authenticateMiddleware,
    validate({ query: listKnowledgeDocumentsQuerySchema }),
    controller.listDocuments,
  );

  router.get(
    '/documents/:id',
    authenticateMiddleware,
    validate({ params: documentIdParamsSchema }),
    controller.getDocument,
  );

  router.delete(
    '/documents/:id',
    authenticateMiddleware,
    requireTeacherMiddleware,
    validate({ params: documentIdParamsSchema }),
    controller.deleteDocument,
  );

  router.post(
    '/reindex',
    authenticateMiddleware,
    requireTeacherMiddleware,
    validate({ body: reindexKnowledgeSchema }),
    controller.reindex,
  );

  router.get('/status', authenticateMiddleware, requireTeacherMiddleware, controller.getStatus);

  return router;
};
