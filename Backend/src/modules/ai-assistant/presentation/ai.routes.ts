import { Router, type RequestHandler } from 'express';
import type { AiController } from './ai.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  fromTopicBodySchema,
  fromUrlBodySchema,
  generateCourseBodySchema,
} from './ai.validation.js';
import { pdfUploadMiddleware } from './pdf-upload.middleware.js';

export interface AiRouterOptions {
  controller: AiController;
  authenticateMiddleware: RequestHandler;
  requireTeacherMiddleware: RequestHandler;
  generateRateLimiter: RequestHandler;
}

export const createAiRouter = (options: AiRouterOptions): Router => {
  const router = Router();
  const { controller, authenticateMiddleware, requireTeacherMiddleware, generateRateLimiter } =
    options;

  router.use(authenticateMiddleware, requireTeacherMiddleware);

  router.get('/status', controller.getStatus);

  router.post(
    '/courses/generate',
    generateRateLimiter,
    validate({ body: generateCourseBodySchema }),
    controller.generateCourse,
  );

  router.post(
    '/courses/from-topic',
    generateRateLimiter,
    validate({ body: fromTopicBodySchema }),
    controller.fromTopic,
  );

  router.post(
    '/courses/from-url',
    generateRateLimiter,
    validate({ body: fromUrlBodySchema }),
    controller.fromUrl,
  );

  router.post(
    '/courses/improve-pdf',
    generateRateLimiter,
    pdfUploadMiddleware,
    controller.improvePdf,
  );

  // Live progress variants (SSE `data:` frames, HTTP 200 + error event
  // on failure — see controller.streamCourse).
  router.post(
    '/courses/stream',
    generateRateLimiter,
    validate({ body: generateCourseBodySchema }),
    controller.streamGenerate,
  );

  router.post(
    '/courses/improve-pdf-stream',
    generateRateLimiter,
    pdfUploadMiddleware,
    controller.streamImprovePdf,
  );

  return router;
};
