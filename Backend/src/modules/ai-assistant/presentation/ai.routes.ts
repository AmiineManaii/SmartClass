import { Router, type RequestHandler } from 'express';
import type { AiController } from './ai.controller.js';
import { validate } from '../../../shared/http/validate.middleware.js';
import {
  fromTopicBodySchema,
  fromUrlBodySchema,
  generateCourseBodySchema,
  generateOutlineBodySchema,
  refineSectionBodySchema,
  validateSectionBodySchema,
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
    '/courses/generate-outline',
    generateRateLimiter,
    validate({ body: generateOutlineBodySchema }),
    controller.generateOutline,
  );

  router.post(
    '/courses/refine-section',
    generateRateLimiter,
    validate({ body: refineSectionBodySchema }),
    controller.refineSection,
  );

  // --- Section-by-section build (RG27: nothing published unvalidated) ---
  // Build state: course metadata + ordered sections (lazily materialized
  // from the teacher-validated outline on first open).
  router.get('/courses/:id/build', controller.getCourseBuild);

  // Generation is validated inline in the controller so a bad payload can
  // still answer 422 before any SSE header is written.
  router.post('/courses/sections/generate', generateRateLimiter, controller.streamGenerateSection);

  router.post(
    '/courses/sections/regenerate',
    generateRateLimiter,
    controller.streamRegenerateSection,
  );

  router.post(
    '/courses/sections/validate',
    validate({ body: validateSectionBodySchema }),
    controller.validateSection,
  );

  // Async ComfyUI jobs: start returns 202 immediately, the client polls.
  // Kept alongside the synchronous endpoint for backward compatibility.
  router.post('/courses/sections/image/jobs', generateRateLimiter, controller.startSectionImageJob);

  router.get('/courses/sections/image/jobs/:jobId', controller.getSectionImageJob);

  router.post('/courses/sections/image', generateRateLimiter, controller.generateSectionImage);

  router.post(
    '/courses/sections/image/search',
    generateRateLimiter,
    controller.searchSectionImages,
  );

  router.post('/courses/sections/image/apply', controller.applySectionImage);

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
