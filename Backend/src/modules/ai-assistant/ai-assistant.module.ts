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
import type { EmbeddingPort } from './domain/embedding.port.js';
import type { SectionMemoryPort } from './domain/section-memory.port.js';
import type { ImageGeneratorPort } from './domain/image-generator.port.js';
import type { ImagePromptOptimizerPort } from './domain/image-prompt-optimizer.port.js';
import type { PdfTextExtractorPort } from './infrastructure/pdf-text-extractor.adapter.js';
import { OpenAICompatibleGateway } from './infrastructure/openai-compatible-gateway.adapter.js';
import { NativeUrlFetcher } from './infrastructure/native-url-fetcher.adapter.js';
import { UnpdfTextExtractor } from './infrastructure/pdf-text-extractor.adapter.js';
import { OllamaEmbeddingAdapter } from './infrastructure/ollama-embedding.adapter.js';
import { PrismaSectionMemoryAdapter } from './infrastructure/prisma-section-memory.adapter.js';
import { ComfyUIImageAdapter } from './infrastructure/comfyui-image.adapter.js';
import { LlmImagePromptOptimizer } from './infrastructure/llm-image-prompt-optimizer.adapter.js';
import type { CourseRepositoryPort } from '../courses/domain/course-repository.port.js';
import type { CourseSectionRepositoryPort } from '../courses/domain/course-section-repository.port.js';
import { PrismaCourseRepositoryAdapter } from '../courses/infrastructure/prisma-course-repository.adapter.js';
import { PrismaCourseSectionRepositoryAdapter } from '../courses/infrastructure/prisma-course-section-repository.adapter.js';
import { GenerateCourseUseCase } from './application/generate-course.use-case.js';
import { GenerateOutlineUseCase } from './application/generate-outline.use-case.js';
import { RefineSectionUseCase } from './application/refine-section.use-case.js';
import { ImprovePdfUseCase } from './application/improve-pdf.use-case.js';
import { GetAiStatusUseCase } from './application/get-ai-status.use-case.js';
import { GetCourseBuildUseCase } from './application/get-course-build.use-case.js';
import { GenerateSectionUseCase } from './application/generate-section.use-case.js';
import { ValidateSectionUseCase } from './application/validate-section.use-case.js';
import { GenerateSectionImageUseCase } from './application/generate-section-image.use-case.js';
import { SearchSectionImagesUseCase } from './application/search-section-images.use-case.js';
import { ApplySectionImageUseCase } from './application/apply-section-image.use-case.js';
import { SectionImageJobService } from './application/section-image-job.service.js';
import { SectionMemoryService } from './application/section-memory.service.js';
import { AiController } from './presentation/ai.controller.js';
import { createAiRouter } from './presentation/ai.routes.js';

import type { SearchPort } from './domain/search.port.js';
import type { SectionImageJobStorePort } from './domain/section-image-job.port.js';
import { HybridSearchAdapter } from './infrastructure/hybrid-search.adapter.js';
import { InMemorySectionImageJobStore } from './infrastructure/in-memory-section-image-job.store.js';

export interface AiModuleOptions {
  gateway?: AiGatewayPort;
  searchService?: SearchPort;
  urlFetcher?: UrlFetcherPort;
  pdfExtractor?: PdfTextExtractorPort;
  courseRepository?: CourseRepositoryPort;
  sectionRepository?: CourseSectionRepositoryPort;
  embedding?: EmbeddingPort;
  sectionMemory?: SectionMemoryPort;
  imageGenerator?: ImageGeneratorPort;
  imagePromptOptimizer?: ImagePromptOptimizerPort;
  imageJobStore?: SectionImageJobStorePort;
  tokenService?: TokenServicePort;
  authenticateMiddleware?: RequestHandler;
  requireTeacherMiddleware?: RequestHandler;
}

export interface AiModule {
  router: Router;
  controller: AiController;
}

export const createAiModule = (options: AiModuleOptions = {}): AiModule => {
  const searchService = options.searchService ?? new HybridSearchAdapter();
  const urlFetcher = options.urlFetcher ?? new NativeUrlFetcher();
  const imageGenerator = options.imageGenerator ?? new ComfyUIImageAdapter();
  const gateway =
    options.gateway ?? new OpenAICompatibleGateway({ searchService, imageGenerator, urlFetcher });
  const pdfExtractor = options.pdfExtractor ?? new UnpdfTextExtractor();
  const courseRepository = options.courseRepository ?? new PrismaCourseRepositoryAdapter();
  const sectionRepository = options.sectionRepository ?? new PrismaCourseSectionRepositoryAdapter();
  const embedding = options.embedding ?? new OllamaEmbeddingAdapter();
  const sectionMemory =
    options.sectionMemory ?? new PrismaSectionMemoryAdapter(undefined, embedding);
  const memoryService = new SectionMemoryService(sectionMemory, embedding);
  const imagePromptOptimizer = options.imagePromptOptimizer ?? new LlmImagePromptOptimizer(gateway);

  const generateCourseUseCase = new GenerateCourseUseCase(gateway, urlFetcher);
  const improvePdfUseCase = new ImprovePdfUseCase(pdfExtractor, gateway);
  const getAiStatusUseCase = new GetAiStatusUseCase(gateway);
  const generateOutlineUseCase = new GenerateOutlineUseCase(gateway);
  const refineSectionUseCase = new RefineSectionUseCase(gateway, courseRepository, memoryService);
  const getCourseBuildUseCase = new GetCourseBuildUseCase(courseRepository, sectionRepository);
  const generateSectionUseCase = new GenerateSectionUseCase(
    gateway,
    courseRepository,
    sectionRepository,
    memoryService,
  );
  const validateSectionUseCase = new ValidateSectionUseCase(
    courseRepository,
    sectionRepository,
    memoryService,
  );
  const generateSectionImageUseCase = new GenerateSectionImageUseCase(
    courseRepository,
    sectionRepository,
    imageGenerator,
    imagePromptOptimizer,
  );
  const searchSectionImagesUseCase = new SearchSectionImagesUseCase(
    courseRepository,
    sectionRepository,
    searchService,
    gateway,
  );
  const applySectionImageUseCase = new ApplySectionImageUseCase(
    courseRepository,
    sectionRepository,
  );
  const sectionImageJobService = new SectionImageJobService(
    courseRepository,
    sectionRepository,
    generateSectionImageUseCase,
    imageGenerator,
    options.imageJobStore ?? new InMemorySectionImageJobStore(),
  );
  const controller = new AiController(
    generateCourseUseCase,
    improvePdfUseCase,
    getAiStatusUseCase,
    generateOutlineUseCase,
    refineSectionUseCase,
    getCourseBuildUseCase,
    generateSectionUseCase,
    validateSectionUseCase,
    generateSectionImageUseCase,
    searchSectionImagesUseCase,
    applySectionImageUseCase,
    sectionImageJobService,
  );

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
