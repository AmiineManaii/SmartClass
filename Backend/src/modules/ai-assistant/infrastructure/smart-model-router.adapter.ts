import { getEnv } from '../../../config/env.js';
import { InternalError, ServiceUnavailableError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type {
  AiGatewayPort,
  ChatCompletionInput,
  ChatCompletionResult,
  StreamCompletionUsage,
} from '../domain/ai-gateway.port.js';
import type {
  LocalModelMetadata,
  ModelInventoryReport,
  ModelRole,
  SmartModelRouterPort,
  VisionCompletionInput,
} from '../domain/model-router.port.js';
import { OpenAICompatibleGateway } from './openai-compatible-gateway.adapter.js';

/**
 * Bounded semaphore ensuring GPU-heavy tasks run sequentially on constrained
 * local hardware (NVIDIA RTX 4060 8GB VRAM).
 */
export class GpuTaskSemaphore {
  private active = 0;
  private readonly queue: Array<() => void> = [];

  constructor(private readonly maxConcurrency = 1) {}

  public async runExclusive<T>(fn: () => Promise<T>): Promise<T> {
    if (this.active >= this.maxConcurrency) {
      await new Promise<void>((resolve) => this.queue.push(resolve));
    }
    this.active++;
    try {
      return await fn();
    } finally {
      this.active--;
      const next = this.queue.shift();
      if (next) next();
    }
  }

  public getActiveCount(): number {
    return this.active;
  }
}

interface OllamaTagsResponse {
  models?: Array<{
    name: string;
    size?: number;
    details?: {
      family?: string;
      parameter_size?: string;
      quantization_level?: string;
    };
  }>;
}

interface OllamaShowResponse {
  capabilities?: string[];
  details?: {
    family?: string;
    parameter_size?: string;
    quantization_level?: string;
  };
  model_info?: Record<string, unknown>;
}

const KNOWN_SECONDARY_CANDIDATES = [
  'hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1',
  'gemma4:e4b',
];

export class SmartModelRouterAdapter implements SmartModelRouterPort {
  private readonly baseUrl: string;
  private readonly configuredPrimary: string;
  private readonly configuredFallback: string;
  private readonly embeddingModel: string;
  private readonly maxConcurrentGpu: number;
  private readonly semaphore: GpuTaskSemaphore;
  private cachedInventory: ModelInventoryReport | null = null;
  private cacheExpiresAt = 0;

  private readonly gatewayFactory: (model: string, fallbackModel: string) => AiGatewayPort;

  constructor(
    gatewayFactory?: (model: string, fallbackModel: string) => AiGatewayPort,
    options?: {
      baseUrl?: string;
      primaryModel?: string;
      fallbackModel?: string;
      embeddingModel?: string;
      maxConcurrentGpu?: number;
    },
  ) {
    const env = getEnv();
    this.baseUrl = (options?.baseUrl ?? env.AI_BASE_URL).replace(/\/+$/, '');
    this.configuredPrimary = options?.primaryModel ?? env.AI_MODEL;
    this.configuredFallback = options?.fallbackModel ?? env.AI_FALLBACK_MODEL;
    this.embeddingModel = options?.embeddingModel ?? env.EMBEDDING_MODEL;
    this.maxConcurrentGpu = Math.max(1, options?.maxConcurrentGpu ?? env.MEDIA_WORKER_CONCURRENCY);
    this.semaphore = new GpuTaskSemaphore(this.maxConcurrentGpu);
    this.gatewayFactory =
      gatewayFactory ??
      ((model: string, fallbackModel: string) =>
        new OpenAICompatibleGateway({
          baseUrl: this.baseUrl,
          model,
          fallbackModel,
        }));
  }

  public async inspectModels(forceRefresh = false): Promise<ModelInventoryReport> {
    return this.inspectInventory(forceRefresh);
  }

  public async inspectInventory(forceRefresh = false): Promise<ModelInventoryReport> {
    const now = Date.now();
    if (!forceRefresh && this.cachedInventory && now < this.cacheExpiresAt) {
      return this.cachedInventory;
    }

    const installedModels: LocalModelMetadata[] = [];
    let available = false;

    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 5000);
      try {
        const res = await fetch(`${this.baseUrl}/api/tags`, { signal: controller.signal });
        if (res.ok) {
          available = true;
          const body = (await res.json().catch(() => null)) as OllamaTagsResponse | null;
          const models = body?.models ?? [];

          for (const item of models) {
            if (item.name.toLowerCase().includes('embedding')) continue;
            const meta = await this.inspectSingleModel(item.name, item.size ?? 0, item.details);
            installedModels.push(meta);
          }
        }
      } finally {
        clearTimeout(timer);
      }
    } catch (err) {
      logger.debug({ err }, 'Ollama inventory inspection failed; using configured model defaults');
    }

    const normalize = (id: string): string => id.replace(/:latest$/, '');

    // Determine primary and secondary from actual installed models
    let primaryTextModel = this.configuredPrimary;
    let secondaryFastModel = this.configuredFallback;

    if (installedModels.length > 0) {
      const matchPrimary = installedModels.find(
        (m) => normalize(m.name) === normalize(this.configuredPrimary),
      );
      primaryTextModel = matchPrimary ? matchPrimary.name : installedModels[0]!.name;

      const otherModels = installedModels.filter(
        (m) => normalize(m.name) !== normalize(primaryTextModel),
      );
      if (otherModels.length > 0) {
        const matchFallback = otherModels.find(
          (m) => normalize(m.name) === normalize(this.configuredFallback),
        );
        secondaryFastModel = matchFallback ? matchFallback.name : otherModels[0]!.name;
      } else {
        // Fallback candidate from known local models
        const alt = KNOWN_SECONDARY_CANDIDATES.find(
          (c) => normalize(c) !== normalize(primaryTextModel),
        );
        secondaryFastModel = alt ?? this.configuredFallback;
      }
    }

    const visionCapable = installedModels.find((m) => m.capabilities.vision);
    const visionModel = visionCapable ? visionCapable.name : null;

    const report: ModelInventoryReport = {
      available,
      inspectedAt: new Date().toISOString(),
      primaryModel: primaryTextModel,
      secondaryModel: secondaryFastModel,
      gpuBudgetVramMb: 8188,
      maxConcurrentGpuTasks: this.maxConcurrentGpu,
      installedModels,
      roleAssignments: {
        primaryTextModel,
        secondaryFastModel,
        visionModel,
        embeddingModel: this.embeddingModel,
        transcriptionEngine: 'faster-whisper / ffmpeg-local',
      },
    };

    this.cachedInventory = report;
    this.cacheExpiresAt = now + 60_000;
    return report;
  }

  private async inspectSingleModel(
    name: string,
    sizeBytes: number,
    tagDetails?: { family?: string; parameter_size?: string; quantization_level?: string },
  ): Promise<LocalModelMetadata> {
    const startedAt = Date.now();
    let capabilitiesList: string[] = ['completion'];
    let contextLength = 32768;
    let family = tagDetails?.family ?? 'unknown';
    let parameterSize = tagDetails?.parameter_size ?? 'unknown';
    let quantizationLevel = tagDetails?.quantization_level ?? 'unknown';

    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 3000);
      try {
        const showRes = await fetch(`${this.baseUrl}/api/show`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ model: name }),
          signal: controller.signal,
        });
        if (showRes.ok) {
          const showBody = (await showRes.json().catch(() => null)) as OllamaShowResponse | null;
          if (Array.isArray(showBody?.capabilities)) {
            capabilitiesList = showBody.capabilities;
          }
          if (showBody?.details?.family) family = showBody.details.family;
          if (showBody?.details?.parameter_size) parameterSize = showBody.details.parameter_size;
          if (showBody?.details?.quantization_level) {
            quantizationLevel = showBody.details.quantization_level;
          }
          if (showBody?.model_info) {
            for (const [k, v] of Object.entries(showBody.model_info)) {
              if (k.endsWith('.context_length') && typeof v === 'number') {
                contextLength = v;
              }
            }
          }
        }
      } finally {
        clearTimeout(timer);
      }
    } catch {
      // Non-fatal metadata enrichment
    }

    const sizeMb = Math.round(sizeBytes / (1024 * 1024));
    const estimatedVramMb = sizeMb > 0 ? Math.round(sizeMb * 1.15) : 3500;

    return {
      name,
      sizeBytes,
      family,
      parameterSize,
      quantizationLevel,
      contextLength,
      capabilities: {
        completion: capabilitiesList.includes('completion'),
        tools: capabilitiesList.includes('tools'),
        thinking: capabilitiesList.includes('thinking'),
        vision: capabilitiesList.includes('vision'),
        audio: capabilitiesList.includes('audio'),
        structuredJson: true,
      },
      estimatedVramMb,
      latencyMs: Date.now() - startedAt,
    };
  }

  private selectModelsForRole(
    role: ModelRole,
    inventory: ModelInventoryReport,
  ): { preferred: string; backup: string } {
    const { primaryTextModel, secondaryFastModel, visionModel } = inventory.roleAssignments;

    switch (role) {
      case 'SUMMARY_FAST':
      case 'STUDENT_SUMMARY':
      case 'QUIZ_FLASHCARDS':
      case 'SPEECH_POST_PROCESSING':
        // Route lightweight/structured student study generation to the faster secondary model first
        // when two distinct models exist, with fallback to primary.
        return {
          preferred: secondaryFastModel || primaryTextModel,
          backup: primaryTextModel,
        };
      case 'VISION_SLIDES':
        return {
          preferred: visionModel ?? primaryTextModel,
          backup: secondaryFastModel,
        };
      case 'ORCHESTRATION':
      case 'LESSON_GENERATION':
      case 'LESSON_PACKAGE_GENERATION':
      case 'TUTOR_RAG':
      case 'AI_TUTOR_RAG':
      case 'QUALITY_VALIDATION':
      default:
        return {
          preferred: primaryTextModel,
          backup: secondaryFastModel,
        };
    }
  }

  public async completeForRole(
    role: ModelRole,
    input: ChatCompletionInput,
  ): Promise<ChatCompletionResult & { role: ModelRole; fallbackUsed: boolean }> {
    const inventory = await this.inspectInventory();
    const { preferred, backup } = this.selectModelsForRole(role, inventory);

    return this.semaphore.runExclusive(async () => {
      const primaryGateway = this.gatewayFactory(preferred, '');
      try {
        const res = await primaryGateway.chatCompletion({
          ...input,
          thinking: input.thinking ?? false,
        });
        return { ...res, role, fallbackUsed: false };
      } catch (primaryErr) {
        if (backup && backup !== preferred) {
          logger.warn(
            { role, preferred, backup, err: primaryErr },
            'SmartModelRouter: preferred model failed, falling back to secondary local model',
          );
          const backupGateway = this.gatewayFactory(backup, '');
          const res = await backupGateway.chatCompletion({
            ...input,
            thinking: false,
          });
          return { ...res, role, fallbackUsed: true };
        }
        throw primaryErr;
      }
    });
  }

  public async generateForRole(
    role: ModelRole,
    input: {
      systemPrompt: string;
      messages: Array<{ role: 'user' | 'assistant' | 'system'; content: string }>;
      temperature?: number;
      maxTokens?: number;
    },
  ): Promise<{ content: string; modelUsed: string; fallbackUsed: boolean }> {
    const userPrompt = input.messages
      .map((m) => (m.role === 'user' ? m.content : `[${m.role.toUpperCase()}]: ${m.content}`))
      .join('\n\n');

    const res = await this.completeForRole(role, {
      system: input.systemPrompt,
      user: userPrompt,
      temperature: input.temperature ?? 0.25,
      maxTokens: input.maxTokens ?? 800,
      thinking: false,
    });

    return {
      content: res.content,
      modelUsed: res.model,
      fallbackUsed: res.fallbackUsed,
    };
  }

  public async streamForRole(
    role: ModelRole,
    input: ChatCompletionInput,
    onDelta: (delta: string) => void,
    onPhase?: (phase: string) => void,
  ): Promise<StreamCompletionUsage & { role: ModelRole; fallbackUsed: boolean }> {
    const inventory = await this.inspectInventory();
    const { preferred, backup } = this.selectModelsForRole(role, inventory);

    return this.semaphore.runExclusive(async () => {
      const primaryGateway = this.gatewayFactory(preferred, '');
      try {
        const usage = await primaryGateway.streamCompletion(
          { ...input, thinking: input.thinking ?? false },
          onDelta,
          onPhase,
        );
        return { ...usage, role, fallbackUsed: false };
      } catch (primaryErr) {
        if (backup && backup !== preferred) {
          logger.warn(
            { role, preferred, backup, err: primaryErr },
            'SmartModelRouter: preferred stream failed, falling back to secondary local model',
          );
          const backupGateway = this.gatewayFactory(backup, '');
          const usage = await backupGateway.streamCompletion(
            { ...input, thinking: false },
            onDelta,
            onPhase,
          );
          return { ...usage, role, fallbackUsed: true };
        }
        throw primaryErr;
      }
    });
  }

  public async analyzeVisualFrame(input: VisionCompletionInput): Promise<ChatCompletionResult> {
    const inventory = await this.inspectInventory();
    const visionModel = inventory.roleAssignments.visionModel;
    if (!visionModel) {
      throw new ServiceUnavailableError(
        'No vision-capable local model is currently available in Ollama',
      );
    }

    return this.semaphore.runExclusive(async () => {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), 90_000);
      try {
        const mime = input.mimeType ?? 'image/jpeg';
        const dataUrl = input.imageBase64.startsWith('data:')
          ? input.imageBase64
          : `data:${mime};base64,${input.imageBase64}`;

        const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            model: visionModel,
            messages: [
              { role: 'system', content: input.system },
              {
                role: 'user',
                content: [
                  { type: 'text', text: input.user },
                  { type: 'image_url', image_url: { url: dataUrl } },
                ],
              },
            ],
            max_tokens: input.maxTokens ?? 600,
            temperature: input.temperature ?? 0.2,
            reasoning_effort: 'none',
            chat_template_kwargs: { enable_thinking: false },
          }),
          signal: controller.signal,
        });

        if (!response.ok) {
          throw new InternalError(`Vision model returned HTTP ${response.status}`);
        }
        const body = (await response.json()) as {
          choices?: Array<{ message?: { content?: string } }>;
          usage?: { prompt_tokens?: number; completion_tokens?: number };
          model?: string;
        };
        const content = body.choices?.[0]?.message?.content?.trim() ?? '';
        return {
          content,
          promptTokens: body.usage?.prompt_tokens ?? null,
          completionTokens: body.usage?.completion_tokens ?? null,
          model: body.model ?? visionModel,
          toolsUsed: false,
        };
      } finally {
        clearTimeout(timer);
      }
    });
  }
}
