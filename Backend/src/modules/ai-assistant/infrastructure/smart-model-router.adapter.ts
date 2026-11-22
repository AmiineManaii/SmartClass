import { getEnv } from '../../../config/env.js';
import { InternalError, ServiceUnavailableError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type {
  AiGatewayPort,
  AiGatewayStatus,
  ChatCompletionInput,
  ChatCompletionResult,
  StreamCompletionUsage,
} from '../domain/ai-gateway.port.js';
import type {
  LocalModelMetadata,
  ModelInventoryReport,
  ModelRole,
  RoleGatewayOptions,
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

const normalizeModelId = (id: string): string => id.replace(/:latest$/, '');

const isEmbeddingModelTag = (name: string, capabilities?: string[]): boolean => {
  if (capabilities?.includes('embedding')) return true;
  return name.toLowerCase().includes('embedding');
};

export interface SmartModelRouterOptions {
  baseUrl?: string;
  primaryModel?: string;
  fallbackModel?: string;
  visionModel?: string;
  structuredModel?: string;
  tutorModel?: string;
  embeddingModel?: string;
  embeddingNumGpu?: number;
  maxConcurrentGpu?: number;
  /** Deterministic override used in unit tests without hitting live Ollama. */
  installedModels?: string[];
}

export class SmartModelRouterAdapter implements SmartModelRouterPort {
  private readonly baseUrl: string;
  private readonly configuredPrimary: string;
  private readonly configuredFallback: string;
  private readonly configuredVision: string;
  private readonly configuredStructured: string;
  private readonly configuredTutor: string;
  private readonly embeddingModel: string;
  private readonly embeddingNumGpu: number;
  private readonly maxConcurrentGpu: number;
  private readonly configuredInstalledModels?: string[];
  private readonly semaphore: GpuTaskSemaphore;
  private cachedInventory: ModelInventoryReport | null = null;
  private cacheExpiresAt = 0;

  private readonly gatewayFactory: (
    model: string,
    fallbackModel: string,
    gatewayOptions?: RoleGatewayOptions,
  ) => AiGatewayPort;

  constructor(
    gatewayFactory?: (
      model: string,
      fallbackModel: string,
      gatewayOptions?: RoleGatewayOptions,
    ) => AiGatewayPort,
    options?: SmartModelRouterOptions,
  ) {
    const env = getEnv();
    this.baseUrl = (options?.baseUrl ?? env.AI_BASE_URL).replace(/\/+$/, '');
    this.configuredPrimary = options?.primaryModel ?? env.AI_PRIMARY_MODEL ?? env.AI_MODEL;
    this.configuredFallback =
      options?.fallbackModel ?? env.AI_SECONDARY_MODEL ?? env.AI_FALLBACK_MODEL;
    this.configuredVision = options?.visionModel ?? env.AI_VISION_MODEL ?? '';
    this.configuredStructured = options?.structuredModel ?? env.AI_STRUCTURED_MODEL ?? '';
    this.configuredTutor = options?.tutorModel ?? env.AI_TUTOR_MODEL ?? '';
    this.embeddingModel = options?.embeddingModel ?? env.EMBEDDING_MODEL;
    this.embeddingNumGpu = options?.embeddingNumGpu ?? env.EMBEDDING_NUM_GPU;
    this.maxConcurrentGpu = Math.max(
      1,
      options?.maxConcurrentGpu ?? env.AI_MAX_CONCURRENT_JOBS ?? env.MEDIA_WORKER_CONCURRENCY,
    );
    this.configuredInstalledModels = options?.installedModels;
    this.semaphore = new GpuTaskSemaphore(this.maxConcurrentGpu);
    this.gatewayFactory =
      gatewayFactory ??
      ((model: string, fallbackModel: string, gatewayOptions?: RoleGatewayOptions) =>
        new OpenAICompatibleGateway({
          baseUrl: this.baseUrl,
          model,
          fallbackModel,
          searchService: gatewayOptions?.searchService,
          imageGenerator: gatewayOptions?.imageGenerator,
          urlFetcher: gatewayOptions?.urlFetcher,
        }));
  }

  public async runOnGpu<T>(fn: () => Promise<T>): Promise<T> {
    return this.semaphore.runExclusive(fn);
  }

  public createGatewayForRole(role: ModelRole, gatewayOptions?: RoleGatewayOptions): AiGatewayPort {
    return {
      chatCompletion: async (input: ChatCompletionInput): Promise<ChatCompletionResult> => {
        const res = await this.completeForRoleWithOptions(role, input, gatewayOptions);
        return {
          content: res.content,
          promptTokens: res.promptTokens,
          completionTokens: res.completionTokens,
          model: res.model,
          toolsUsed: res.toolsUsed,
        };
      },
      streamCompletion: async (
        input: ChatCompletionInput,
        onDelta: (delta: string) => void,
        onPhase?: (phase: string) => void,
      ): Promise<StreamCompletionUsage> => {
        const usage = await this.streamForRoleWithOptions(
          role,
          input,
          onDelta,
          onPhase,
          gatewayOptions,
        );
        return {
          promptTokens: usage.promptTokens,
          completionTokens: usage.completionTokens,
          model: usage.model,
        };
      },
      checkHealth: async (): Promise<AiGatewayStatus> => {
        const inventory = await this.inspectInventory(true);
        const { preferred } = this.selectModelsForRole(role, inventory);
        const match = inventory.installedModels.find(
          (m) => normalizeModelId(m.name) === normalizeModelId(preferred),
        );
        return {
          available: inventory.available,
          model: preferred,
          latencyMs: match?.latencyMs ?? null,
        };
      },
    };
  }

  public async inspectModels(forceRefresh = false): Promise<ModelInventoryReport> {
    return this.inspectInventory(forceRefresh);
  }

  public async inspectInventory(forceRefresh = false): Promise<ModelInventoryReport> {
    const now = Date.now();
    if (!forceRefresh && this.cachedInventory && now < this.cacheExpiresAt) {
      return {
        ...this.cachedInventory,
        activeGpuTasks: this.semaphore.getActiveCount(),
      };
    }

    const installedModels: LocalModelMetadata[] = [];
    const installedEmbeddingModels: string[] = [];
    let available = false;

    if (this.configuredInstalledModels) {
      available = this.configuredInstalledModels.length > 0;
      for (const name of this.configuredInstalledModels) {
        if (isEmbeddingModelTag(name)) {
          installedEmbeddingModels.push(name);
          continue;
        }
        const lower = name.toLowerCase();
        installedModels.push({
          name,
          sizeBytes: 0,
          family: lower.includes('gemma') ? 'gemma4' : lower.includes('qwen') ? 'qwen3' : 'local',
          parameterSize: '4B',
          quantizationLevel: 'Q4',
          contextLength: 32768,
          capabilities: {
            completion: true,
            tools: true,
            thinking: true,
            vision: lower.includes('gemma4') || lower.includes('vl') || lower.includes('vision'),
            audio: lower.includes('gemma4'),
            structuredJson: true,
          },
          estimatedVramMb: 4500,
          latencyMs: 5,
        });
      }
    } else {
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
              const meta = await this.inspectSingleModel(
                item.name,
                item.size ?? 0,
                item.details,
              );
              if (meta.isEmbedding) {
                installedEmbeddingModels.push(item.name);
                continue;
              }
              installedModels.push(meta.metadata);
            }
          }
        } finally {
          clearTimeout(timer);
        }
      } catch (err) {
        logger.debug({ err }, 'Ollama inventory inspection failed; using configured model defaults');
      }
    }

    const findInstalled = (candidate: string): LocalModelMetadata | undefined => {
      if (!candidate.trim()) return undefined;
      return installedModels.find((m) => normalizeModelId(m.name) === normalizeModelId(candidate));
    };

    // Determine primary and optional secondary strictly from ACTUAL installed models (no ghost 404s)
    let primaryTextModel = this.configuredPrimary;
    let secondaryModel: string | null = null;
    let secondaryInstalled = false;

    if (installedModels.length > 0) {
      const matchPrimary = findInstalled(this.configuredPrimary);
      primaryTextModel = matchPrimary ? matchPrimary.name : installedModels[0]!.name;

      const otherModels = installedModels.filter(
        (m) => normalizeModelId(m.name) !== normalizeModelId(primaryTextModel),
      );
      if (otherModels.length > 0) {
        const matchSecondary = findInstalled(this.configuredFallback);
        const resolvedSecondary =
          matchSecondary &&
          normalizeModelId(matchSecondary.name) !== normalizeModelId(primaryTextModel)
            ? matchSecondary.name
            : otherModels[0]!.name;
        secondaryModel = resolvedSecondary;
        secondaryInstalled = true;
      }
    }

    const secondaryFastModel = secondaryModel ?? primaryTextModel;

    const visionCapable =
      (this.configuredVision ? findInstalled(this.configuredVision) : undefined) ??
      installedModels.find((m) => m.capabilities.vision);
    const visionModel = visionCapable ? visionCapable.name : null;

    const structuredMatch = this.configuredStructured
      ? findInstalled(this.configuredStructured)
      : undefined;
    const structuredModel = structuredMatch?.name ?? (secondaryInstalled ? secondaryFastModel : primaryTextModel);

    const tutorMatch = this.configuredTutor ? findInstalled(this.configuredTutor) : undefined;
    const tutorModel = tutorMatch?.name ?? primaryTextModel;

    const resolvedEmbeddingModel =
      installedEmbeddingModels.find(
        (tag) => normalizeModelId(tag) === normalizeModelId(this.embeddingModel),
      ) ?? this.embeddingModel;

    const report: ModelInventoryReport = {
      available,
      inspectedAt: new Date().toISOString(),
      primaryModel: primaryTextModel,
      secondaryModel,
      secondaryInstalled,
      gpuBudgetVramMb: 8188,
      maxConcurrentGpuTasks: this.maxConcurrentGpu,
      activeGpuTasks: this.semaphore.getActiveCount(),
      installedModels,
      installedEmbeddingModels,
      roleAssignments: {
        primaryTextModel,
        secondaryFastModel,
        secondaryInstalled,
        visionModel,
        structuredModel,
        tutorModel,
        embeddingModel: resolvedEmbeddingModel,
        embeddingRuntime: this.embeddingNumGpu === 0 ? 'cpu' : 'gpu',
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
  ): Promise<{ metadata: LocalModelMetadata; isEmbedding: boolean }> {
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
      isEmbedding: isEmbeddingModelTag(name, capabilitiesList),
      metadata: {
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
      },
    };
  }

  private selectModelsForRole(
    role: ModelRole,
    inventory: ModelInventoryReport,
  ): { preferred: string; backup: string | null } {
    const {
      primaryTextModel,
      secondaryFastModel,
      secondaryInstalled,
      visionModel,
      structuredModel,
      tutorModel,
    } = inventory.roleAssignments;

    const distinctBackup = (preferred: string): string | null => {
      if (!secondaryInstalled) return null;
      const alt =
        normalizeModelId(preferred) === normalizeModelId(primaryTextModel)
          ? secondaryFastModel
          : primaryTextModel;
      return normalizeModelId(alt) === normalizeModelId(preferred) ? null : alt;
    };

    switch (role) {
      case 'SUMMARY_FAST':
      case 'STUDENT_SUMMARY':
      case 'QUIZ_FLASHCARDS':
      case 'SPEECH_POST_PROCESSING':
      case 'STRUCTURED_JSON': {
        const preferred = secondaryInstalled
          ? structuredModel || secondaryFastModel
          : primaryTextModel;
        return {
          preferred,
          backup: distinctBackup(preferred),
        };
      }
      case 'VISION_SLIDES': {
        const preferred = visionModel ?? primaryTextModel;
        return {
          preferred,
          backup: distinctBackup(preferred),
        };
      }
      case 'TUTOR_RAG':
      case 'AI_TUTOR_RAG': {
        const preferred = tutorModel || primaryTextModel;
        return {
          preferred,
          backup: distinctBackup(preferred),
        };
      }
      case 'ORCHESTRATION':
      case 'COURSE_GENERATION':
      case 'OUTLINE_GENERATION':
      case 'SECTION_GENERATION':
      case 'EXAM_GENERATION':
      case 'LESSON_GENERATION':
      case 'LESSON_PACKAGE_GENERATION':
      case 'QUALITY_VALIDATION':
      default: {
        const preferred = primaryTextModel;
        return {
          preferred,
          backup: distinctBackup(preferred),
        };
      }
    }
  }

  public async completeForRole(
    role: ModelRole,
    input: ChatCompletionInput,
  ): Promise<ChatCompletionResult & { role: ModelRole; fallbackUsed: boolean }> {
    return this.completeForRoleWithOptions(role, input);
  }

  private async completeForRoleWithOptions(
    role: ModelRole,
    input: ChatCompletionInput,
    gatewayOptions?: RoleGatewayOptions,
  ): Promise<ChatCompletionResult & { role: ModelRole; fallbackUsed: boolean }> {
    const inventory = await this.inspectInventory();
    const { preferred, backup } = this.selectModelsForRole(role, inventory);

    return this.semaphore.runExclusive(async () => {
      const primaryGateway = this.gatewayFactory(preferred, preferred, gatewayOptions);
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
            'SmartModelRouter: preferred model failed, falling back to installed secondary model',
          );
          const backupGateway = this.gatewayFactory(backup, backup, gatewayOptions);
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
    return this.streamForRoleWithOptions(role, input, onDelta, onPhase);
  }

  private async streamForRoleWithOptions(
    role: ModelRole,
    input: ChatCompletionInput,
    onDelta: (delta: string) => void,
    onPhase?: (phase: string) => void,
    gatewayOptions?: RoleGatewayOptions,
  ): Promise<StreamCompletionUsage & { role: ModelRole; fallbackUsed: boolean }> {
    const inventory = await this.inspectInventory();
    const { preferred, backup } = this.selectModelsForRole(role, inventory);

    return this.semaphore.runExclusive(async () => {
      const primaryGateway = this.gatewayFactory(preferred, preferred, gatewayOptions);
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
            'SmartModelRouter: preferred stream failed, falling back to installed secondary model',
          );
          const backupGateway = this.gatewayFactory(backup, backup, gatewayOptions);
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
      const timer = setTimeout(() => controller.abort(), 180_000);
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
