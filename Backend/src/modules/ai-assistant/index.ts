export { createAiModule, type AiModule, type AiModuleOptions } from './ai-assistant.module.js';
export type { AiGatewayPort, ChatCompletionInput, ChatCompletionResult, StreamCompletionUsage } from './domain/ai-gateway.port.js';
export type { EmbeddingPort } from './domain/embedding.port.js';
export type {
  SmartModelRouterPort,
  ModelInventoryReport,
  ModelRole,
  LocalModelMetadata,
  VisionCompletionInput,
} from './domain/model-router.port.js';
export { SmartModelRouterAdapter, GpuTaskSemaphore } from './infrastructure/smart-model-router.adapter.js';
export { OpenAICompatibleGateway } from './infrastructure/openai-compatible-gateway.adapter.js';
export { OllamaEmbeddingAdapter, embedWithFallback, computeDeterministicLexicalVector } from './infrastructure/ollama-embedding.adapter.js';
export { UnpdfTextExtractor, type PdfTextExtractorPort } from './infrastructure/pdf-text-extractor.adapter.js';
export { buildCoursePrompt, COURSE_PROMPT_VERSION, maxTokensForLevel, shouldOfferTools } from './domain/course-prompt.js';

