import type { AiGatewayPort, ChatCompletionInput, ChatCompletionResult, StreamCompletionUsage } from './ai-gateway.port.js';
import type { ImageGeneratorPort } from './image-generator.port.js';
import type { SearchPort } from './search.port.js';
import type { UrlFetcherPort } from './url-fetcher.port.js';

export type ModelRole =
  | 'ORCHESTRATION'
  | 'COURSE_GENERATION'
  | 'OUTLINE_GENERATION'
  | 'SECTION_GENERATION'
  | 'EXAM_GENERATION'
  | 'STRUCTURED_JSON'
  | 'LESSON_GENERATION'
  | 'LESSON_PACKAGE_GENERATION'
  | 'SPEECH_POST_PROCESSING'
  | 'SUMMARY_FAST'
  | 'STUDENT_SUMMARY'
  | 'QUIZ_FLASHCARDS'
  | 'VISION_SLIDES'
  | 'TUTOR_RAG'
  | 'AI_TUTOR_RAG'
  | 'QUALITY_VALIDATION';

export interface RoleGatewayOptions {
  searchService?: SearchPort;
  imageGenerator?: ImageGeneratorPort;
  urlFetcher?: UrlFetcherPort;
}

export interface LocalModelMetadata {
  name: string;
  sizeBytes: number;
  family: string;
  parameterSize: string;
  quantizationLevel: string;
  contextLength: number;
  capabilities: {
    completion: boolean;
    tools: boolean;
    thinking: boolean;
    vision: boolean;
    audio: boolean;
    structuredJson: boolean;
  };
  estimatedVramMb: number;
  latencyMs: number | null;
}

export interface ModelInventoryReport {
  available: boolean;
  inspectedAt: string;
  primaryModel: string;
  secondaryModel: string | null;
  secondaryInstalled: boolean;
  gpuBudgetVramMb: number;
  maxConcurrentGpuTasks: number;
  activeGpuTasks: number;
  installedModels: LocalModelMetadata[];
  installedEmbeddingModels: string[];
  roleAssignments: {
    primaryTextModel: string;
    secondaryFastModel: string;
    secondaryInstalled: boolean;
    visionModel: string | null;
    structuredModel: string;
    tutorModel: string;
    embeddingModel: string;
    embeddingRuntime: 'cpu' | 'gpu';
    transcriptionEngine: string;
  };
}

export interface VisionCompletionInput {
  system: string;
  user: string;
  imageBase64: string;
  mimeType?: string;
  maxTokens?: number;
  temperature?: number;
}

export interface SmartModelRouterPort {
  /**
   * Inspects the live Ollama server (`/api/tags` and `/api/show`), records
   * capabilities of installed generation/embedding models, and assigns roles.
   */
  inspectInventory(forceRefresh?: boolean): Promise<ModelInventoryReport>;
  inspectModels(forceRefresh?: boolean): Promise<ModelInventoryReport>;

  /**
   * Acquires the shared GPU execution semaphore for any local GPU inference task.
   */
  runOnGpu<T>(fn: () => Promise<T>): Promise<T>;

  /**
   * Creates an AiGatewayPort bound to `role` that resolves installed primary/secondary
   * models dynamically and serializes through the shared GPU semaphore.
   */
  createGatewayForRole(role: ModelRole, gatewayOptions?: RoleGatewayOptions): AiGatewayPort;

  /**
   * Executes a chat completion routed to the best local model for `role`,
   * serialized through the GPU concurrency semaphore with automatic fallback
   * to an installed secondary local model if available.
   */
  completeForRole(
    role: ModelRole,
    input: ChatCompletionInput,
  ): Promise<ChatCompletionResult & { role: ModelRole; fallbackUsed: boolean }>;

  generateForRole(
    role: ModelRole,
    input: {
      systemPrompt: string;
      messages: Array<{ role: 'user' | 'assistant' | 'system'; content: string }>;
      temperature?: number;
      maxTokens?: number;
    },
  ): Promise<{ content: string; modelUsed: string; fallbackUsed: boolean }>;

  /**
   * Executes a streaming completion routed to the best local model for `role`.
   */
  streamForRole(
    role: ModelRole,
    input: ChatCompletionInput,
    onDelta: (delta: string) => void,
    onPhase?: (phase: string) => void,
  ): Promise<StreamCompletionUsage & { role: ModelRole; fallbackUsed: boolean }>;

  /**
   * Analyzes a slide/video frame using a verified local vision-capable model.
   * Never contacts external APIs.
   */
  analyzeVisualFrame(input: VisionCompletionInput): Promise<ChatCompletionResult>;
}
