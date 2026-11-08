import type { ChatCompletionInput, ChatCompletionResult, StreamCompletionUsage } from './ai-gateway.port.js';

export type ModelRole =
  | 'ORCHESTRATION'
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
  secondaryModel: string;
  gpuBudgetVramMb: number;
  maxConcurrentGpuTasks: number;
  installedModels: LocalModelMetadata[];
  roleAssignments: {
    primaryTextModel: string;
    secondaryFastModel: string;
    visionModel: string | null;
    embeddingModel: string;
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
   * capabilities of both installed generation models, and assigns roles.
   */
  inspectInventory(forceRefresh?: boolean): Promise<ModelInventoryReport>;
  inspectModels(forceRefresh?: boolean): Promise<ModelInventoryReport>;

  /**
   * Executes a chat completion routed to the best local model for `role`,
   * serialized through the GPU concurrency semaphore with automatic fallback
   * to the secondary local model if the primary fails.
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
