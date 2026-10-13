import { Router, type RequestHandler } from 'express';
import type { Role } from '../auth/index.js';
import {
  createAuthenticateMiddleware,
  createRequireRoleMiddleware,
  type TokenServicePort,
} from '../auth/index.js';
import { createRateLimiter } from '../../shared/http/rate-limiter.js';
import { ipKeyGenerator } from 'express-rate-limit';
import type { AiGatewayPort } from './domain/ai-gateway.port.js';
import type { UrlFetcherPort } from './domain/url-fetcher.port.js';
import type { PdfTextExtractorPort } from './infrastructure/pdf-text-extractor.adapter.js';
import { OpenAICompatibleGateway } from './infrastructure/openai-compatible-gateway.adapter.js';
import { NativeUrlFetcher } from './infrastructure/native-url-fetcher.adapter.js';
import { UnpdfTextExtractor } from './infrastructure/pdf-text-extractor.adapter.js';
import { GenerateCourseUseCase } from './application/generate-course.use-case.js';
import { ImprovePdfUseCase } from './application/improve-pdf.use-case.js';
import { GetAiStatusUseCase } from './application/get-ai-status.use-case.js';
import { AiController } from './presentation/ai.controller.js';
import { createAiRouter } from './presentation/ai.routes.js';

export interface AiModuleOptions {
  gateway?: AiGatewayPort;
  urlFetcher?: UrlFetcherPort;
  pdfExtractor?: PdfTextExtractorPort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireTeacherMiddleware?: RequestHandler;
}

export interface AiModule {
  router: Router;
  controller: AiController;
}

export const createAiModule = (options: AiModuleOptions = {}): AiModule => {
  const gateway = options.gateway ?? new OpenAICompatibleGateway();
  const urlFetcher = options.urlFetcher ?? new NativeUrlFetcher();
  const pdfExtractor = options.pdfExtractor ?? new UnpdfTextExtractor();
  const generateCourseUseCase = new GenerateCourseUseCase(gateway, urlFetcher);
  const improvePdfUseCase = new ImprovePdfUseCase(pdfExtractor, gateway);
  const getAiStatusUseCase = new GetAiStatusUseCase(gateway);
  const controller = new AiController(generateCourseUseCase, improvePdfUseCase, getAiStatusUseCase);

  let authenticateMiddleware = options.authenticateMiddleware;
  if (!authenticateMiddleware) {
    const tokenService = options.tokenService;
    if (!tokenService) {
      throw new Error('AiModule requires authenticateMiddleware or tokenService');
    }
    authenticateMiddleware = createAuthenticateMiddleware(tokenService);
  }

  const requireTeacherMiddleware =
    options.requireTeacherMiddleware ?? createRequireRoleMiddleware(['TEACHER', 'ADMIN'] as Role[]);

  // Strict scope: local LLM generations are expensive (20/min per teacher).
  // req.ip goes through ipKeyGenerator (IPv6-safe, required by the lib).
  const generateRateLimiter = createRateLimiter({
    windowMs: 60000,
    limit: 20,
    message: 'Too many course generations, please try again later',
    keyGenerator: (req) =>
      (req.user as { id?: string } | undefined)?.id ?? ipKeyGenerator(req.ip ?? 'unknown'),
  });

  const router = createAiRouter({
    controller,
    authenticateMiddleware,
    requireTeacherMiddleware,
    generateRateLimiter,
  });

  return { router, controller };
};
