import { getEnv } from '../../../config/env.js';
import {
  InternalError,
  ServiceUnavailableError,
} from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type {
  AiGatewayPort,
  AiGatewayStatus,
  ChatCompletionInput,
  ChatCompletionResult,
  ChatTool,
  StreamCompletionUsage,
} from '../domain/ai-gateway.port.js';
import type { SearchPort } from '../domain/search.port.js';
import type { ImageGeneratorPort } from '../domain/image-generator.port.js';
import type { UrlFetcherPort } from '../domain/url-fetcher.port.js';

interface ChatCompletionsBody {
  choices?: Array<{
    message?: {
      content?: unknown;
      tool_calls?: Array<{
        id: string;
        type: string;
        function: { name: string; arguments: string };
      }>;
    };
    finish_reason?: string;
  }>;
  usage?: {
    prompt_tokens?: number;
    completion_tokens?: number;
  };
  model?: string;
  error?: { message?: string; code?: string | number };
}

const extractText = (content: unknown): string => {
  if (typeof content === 'string') return content;
  if (Array.isArray(content)) {
    return content
      .filter(
        (part): part is { type: string; text?: string } =>
          typeof part === 'object' && part !== null,
      )
      .map((part) => (typeof part.text === 'string' ? part.text : ''))
      .join('');
  }
  return '';
};

export interface OpenAICompatibleGatewayParams {
  baseUrl?: string;
  model?: string;
  fallbackModel?: string;
  apiKey?: string;
  timeoutMs?: number;
  statusTimeoutMs?: number;
  searchService?: SearchPort;
  imageGenerator?: ImageGeneratorPort;
  urlFetcher?: UrlFetcherPort;
}

export class OpenAICompatibleGateway implements AiGatewayPort {
  private readonly baseUrl: string;
  private readonly model: string;
  private readonly fallbackModel: string;
  private readonly apiKey: string;
  private readonly timeoutMs: number;
  private readonly statusTimeoutMs: number;
  private readonly searchService?: SearchPort;
  private readonly imageGenerator?: ImageGeneratorPort;
  private readonly urlFetcher?: UrlFetcherPort;

  constructor(params?: OpenAICompatibleGatewayParams) {
    const env = getEnv();
    this.baseUrl = (params?.baseUrl ?? env.AI_BASE_URL).replace(/\/+$/, '');
    this.model = params?.model ?? env.AI_MODEL;
    this.fallbackModel = params?.fallbackModel ?? env.AI_FALLBACK_MODEL;
    this.apiKey = params?.apiKey ?? env.AI_API_KEY;
    this.timeoutMs = params?.timeoutMs ?? env.AI_TIMEOUT_MS;
    this.statusTimeoutMs = params?.statusTimeoutMs ?? env.AI_STATUS_TIMEOUT_MS;
    this.searchService = params?.searchService;
    this.imageGenerator = params?.imageGenerator;
    this.urlFetcher = params?.urlFetcher;
  }

  /**
   * Ollama exposes chain-of-thought control through `reasoning_effort`
   * (`none` disables it, `low|medium|high` enables it). Qwen3.x otherwise
   * always thinks, burning the token budget before emitting content, so
   * `reasoning_effort` is the reliable switch. `chat_template_kwargs` is
   * still sent for gateways that read it; unknown fields are ignored.
   * Tool calls use the standard OpenAI `tools` / `tool_calls` protocol and
   * are executed by this adapter loop.
   */
  private thinkingParams(thinking: boolean | undefined): Record<string, unknown> {
    const env = getEnv();
    const enabled = thinking ?? env.AI_ENABLE_THINKING;
    return {
      reasoning_effort: enabled ? 'high' : 'none',
      chat_template_kwargs: { enable_thinking: enabled },
    };
  }

  private async executeTool(call: {
    id: string;
    function: { name: string; arguments: string };
  }): Promise<string> {
    const name = call.function.name;
    let args: Record<string, unknown> = {};
    try {
      args = JSON.parse(call.function.arguments || '{}') as Record<string, unknown>;
    } catch {
      args = {};
    }

    logger.info({ tool: name, args }, 'Executing tool call on AI gateway');

    try {
      if (name === 'web_search') {
        const query = typeof args.query === 'string' ? args.query : '';
        const limit = typeof args.max_results === 'number' ? args.max_results : 5;
        if (!this.searchService) {
          return JSON.stringify({ results: [], notice: 'Web search not configured' });
        }
        const results = await this.searchService.searchWeb(query, limit);
        return JSON.stringify({ results });
      }

      if (name === 'image_search') {
        const query = typeof args.query === 'string' ? args.query : '';
        const limit = typeof args.max_results === 'number' ? args.max_results : 5;
        if (!this.searchService) {
          return JSON.stringify({ images: [], notice: 'Image search not configured' });
        }
        const images = await this.searchService.searchImages(query, limit);
        return JSON.stringify({
          images: images.map((img) => ({
            title: img.title,
            url: img.url,
            caption: img.caption,
            markdown: `![${img.caption || img.title}](${img.url})`,
          })),
        });
      }

      if (name === 'generate_image') {
        const prompt = typeof args.prompt === 'string' ? args.prompt : '';
        const negative = typeof args.negative_prompt === 'string' ? args.negative_prompt : undefined;
        if (!this.imageGenerator) {
          return JSON.stringify({ error: 'ComfyUI image generator is not configured. Use image_search.' });
        }
        const isAvailable = await this.imageGenerator.isAvailable();
        if (!isAvailable) {
          return JSON.stringify({
            error: 'ComfyUI server is currently offline or unreachable at port 8188. Use image_search instead.',
          });
        }
        const result = await this.imageGenerator.generate({
          positive: prompt,
          negative,
          kind: 'FIGURE',
        });
        return JSON.stringify({
          imageUrl: result.imageUrl,
          markdown: `![${prompt}](${result.imageUrl})`,
        });
      }

      if (name === 'fetch_url') {
        const url = typeof args.url === 'string' ? args.url : '';
        if (!this.urlFetcher) {
          return JSON.stringify({ error: 'URL fetcher not configured' });
        }
        const fetched = await this.urlFetcher.fetchText(url);
        return JSON.stringify({ title: fetched.title, content: fetched.text.slice(0, 4000) });
      }

      if (name === 'calculator') {
        const expression = typeof args.expression === 'string' ? args.expression : '';
        if (/^[0-9+\-*/().\s%]+$/.test(expression)) {
          try {
            const val = Function(`'use strict'; return (${expression})`)();
            return JSON.stringify({ expression, result: val });
          } catch {
            return JSON.stringify({ error: 'Invalid expression' });
          }
        }
        return JSON.stringify({ error: 'Unsafe mathematical expression' });
      }

      if (name === 'execute_code') {
        return JSON.stringify({
          notice: 'Code sandbox execution is simulated. Reason mathematically or analytically.',
        });
      }

      return JSON.stringify({ error: `Unknown tool: ${name}` });
    } catch (err) {
      logger.warn({ tool: name, error: (err as Error).message }, 'Tool execution failed');
      return JSON.stringify({ error: (err as Error).message });
    }
  }

  private async postMessages(
    messages: Array<Record<string, unknown>>,
    input: { maxTokens?: number; temperature?: number; thinking?: boolean },
    tools: ChatTool[] | undefined,
    timeoutMs: number,
    modelName: string = this.model,
  ): Promise<ChatCompletionsBody & { httpStatus: number }> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...(this.apiKey ? { Authorization: `Bearer ${this.apiKey}` } : {}),
        },
        body: JSON.stringify({
          model: modelName,
          messages,
          max_tokens: input.maxTokens,
          temperature: input.temperature,
          ...this.thinkingParams(input.thinking),
          ...(tools && tools.length > 0
            ? { tools, tool_choice: 'auto' }
            : {}),
        }),
        signal: controller.signal,
      });
      const body = (await response.json().catch(() => null)) as ChatCompletionsBody | null;
      return { httpStatus: response.status, ...(body ?? {}) } as ChatCompletionsBody & {
        httpStatus: number;
      };
    } finally {
      clearTimeout(timer);
    }
  }

  private async postCompletions(
    input: ChatCompletionInput,
    tools: ChatTool[] | undefined,
    timeoutMs: number,
    modelName: string = this.model,
  ): Promise<ChatCompletionsBody & { httpStatus: number }> {
    const messages = [
      { role: 'system', content: input.system },
      { role: 'user', content: input.user },
    ];
    return this.postMessages(messages, input, tools, timeoutMs, modelName);
  }

  private async postMessagesOrThrow(
    messages: Array<Record<string, unknown>>,
    input: ChatCompletionInput,
    tools: ChatTool[] | undefined,
    modelName: string = this.model,
  ): Promise<ChatCompletionsBody & { httpStatus: number }> {
    try {
      return await this.postMessages(messages, input, tools, this.timeoutMs, modelName);
    } catch (error) {
      logger.warn({ err: error, model: modelName }, 'AI gateway request failed');
      throw new ServiceUnavailableError(
        'The local AI model is currently unreachable. Start Ollama and retry.',
      );
    }
  }

  public async chatCompletion(input: ChatCompletionInput): Promise<ChatCompletionResult> {
    let tools = input.tools && input.tools.length > 0 ? input.tools : undefined;
    let activeModel = this.model;

    const messages: Array<Record<string, unknown>> = [
      { role: 'system', content: input.system },
      { role: 'user', content: input.user },
    ];

    let toolsUsed = tools !== undefined;
    let iterations = 0;
    const MAX_TOOL_TURNS = 5;

    while (iterations < MAX_TOOL_TURNS) {
      iterations++;
      let raw: ChatCompletionsBody & { httpStatus: number };
      try {
        raw = await this.postMessagesOrThrow(messages, input, tools, activeModel);
      } catch (err) {
        if (this.fallbackModel && this.fallbackModel !== activeModel) {
          logger.warn(
            { primary: activeModel, fallback: this.fallbackModel, error: err },
            'Primary AI model unreachable, attempting fallback model',
          );
          activeModel = this.fallbackModel;
          raw = await this.postMessagesOrThrow(messages, input, tools, activeModel);
        } else {
          throw err;
        }
      }

      // If model not found (404) or server error (500) with primary model, retry with fallback
      if (
        (raw.httpStatus === 404 || raw.httpStatus >= 500) &&
        this.fallbackModel &&
        this.fallbackModel !== activeModel
      ) {
        logger.warn(
          { primary: activeModel, fallback: this.fallbackModel, status: raw.httpStatus },
          'Primary AI model returned error, attempting fallback model',
        );
        activeModel = this.fallbackModel;
        raw = await this.postMessagesOrThrow(messages, input, tools, activeModel);
      }

      // The local server may not support tool calling (400): degrade
      // gracefully by retrying the same prompt without tools.
      if (raw.httpStatus === 400 && tools !== undefined) {
        logger.info('AI gateway rejected tools, retrying without them');
        toolsUsed = false;
        tools = undefined;
        raw = await this.postMessagesOrThrow(messages, input, undefined, activeModel);
      }

      if (raw.httpStatus === 429) {
        throw new ServiceUnavailableError('The local AI model is overloaded, please retry later.');
      }
      if (raw.httpStatus === 401 || raw.httpStatus === 403) {
        logger.error({ status: raw.httpStatus }, 'AI gateway authentication failed');
        throw new InternalError('AI gateway authentication failed (check AI_API_KEY).');
      }
      if (raw.httpStatus < 200 || raw.httpStatus >= 300 || raw.error) {
        logger.error({ status: raw.httpStatus, error: raw.error }, 'AI gateway error');
        throw new InternalError('Course generation failed on the AI gateway.');
      }

      const choice = raw.choices?.[0];
      const toolCalls = choice?.message?.tool_calls;

      // When the model requests tool calls (Ollama autonomous tool calling):
      if (toolCalls && toolCalls.length > 0) {
        toolsUsed = true;
        messages.push(choice.message as Record<string, unknown>);
        for (const toolCall of toolCalls) {
          const result = await this.executeTool(toolCall);
          messages.push({
            role: 'tool',
            tool_call_id: toolCall.id,
            content: result,
          });
        }
        // Continue loop so the model consumes the tool outputs
        continue;
      }

      // No tool calls: final content produced!
      const content = extractText(choice?.message?.content).trim();
      if (!content) {
        logger.error('AI gateway returned an empty completion');
        throw new InternalError('Course generation returned an empty result.');
      }

      return {
        content,
        promptTokens: raw.usage?.prompt_tokens ?? null,
        completionTokens: raw.usage?.completion_tokens ?? null,
        model: raw.model ?? activeModel,
        toolsUsed,
      };
    }

    throw new InternalError('Exceeded maximum tool calling iterations.');
  }

  private async postOrThrow(
    input: ChatCompletionInput,
    tools: ChatTool[] | undefined,
    modelName: string = this.model,
  ): Promise<ChatCompletionsBody & { httpStatus: number }> {
    try {
      return await this.postCompletions(input, tools, this.timeoutMs, modelName);
    } catch (error) {
      logger.warn({ err: error, model: modelName }, 'AI gateway request failed');
      throw new ServiceUnavailableError(
        'The local AI model is currently unreachable. Start Ollama and retry.',
      );
    }
  }

  public async streamCompletion(
    input: ChatCompletionInput,
    onDelta: (delta: string) => void,
  ): Promise<StreamCompletionUsage> {
    let tools = input.tools && input.tools.length > 0 ? input.tools : undefined;
    let activeModel = this.model;

    const messages: Array<Record<string, unknown>> = [
      { role: 'system', content: input.system },
      { role: 'user', content: input.user },
    ];

    // If tools are offered, run tool turns first to resolve web searches, images, etc.
    if (tools && tools.length > 0) {
      let turns = 0;
      while (turns < 3) {
        turns++;
        let checkRes: (ChatCompletionsBody & { httpStatus: number }) | null = null;
        try {
          checkRes = await this.postMessages(messages, input, tools, this.timeoutMs, activeModel);
        } catch {
          break;
        }
        if (checkRes.httpStatus === 400) {
          tools = undefined;
          break;
        }
        const choice = checkRes.choices?.[0];
        const toolCalls = choice?.message?.tool_calls;
        if (toolCalls && toolCalls.length > 0) {
          messages.push(choice.message as Record<string, unknown>);
          for (const tc of toolCalls) {
            const out = await this.executeTool(tc);
            messages.push({ role: 'tool', tool_call_id: tc.id, content: out });
          }
        } else {
          break;
        }
      }
    }

    let stream: ReadableStream<Uint8Array> | null = null;
    try {
      stream = await this.openStreamWithMessages(messages, input, tools, activeModel);
    } catch (err) {
      if (this.fallbackModel && this.fallbackModel !== activeModel) {
        logger.warn(
          { primary: activeModel, fallback: this.fallbackModel, error: err },
          'Primary AI model stream failed, attempting fallback model',
        );
        activeModel = this.fallbackModel;
        stream = await this.openStreamWithMessages(messages, input, tools, activeModel);
      } else {
        throw err;
      }
    }

    if (stream === null) {
      logger.info('AI gateway rejected tools, retrying stream without them');
      stream = await this.openStreamWithMessages(messages, input, undefined, activeModel);
      if (stream === null) {
        throw new InternalError('Course generation failed on the AI gateway.');
      }
    }

    try {
      return await this.consumeStream(stream, onDelta);
    } finally {
      await stream.cancel().catch(() => undefined);
    }
  }

  /**
   * Opens the SSE stream. Returns `null` when the server rejects the
   * request shape (400 with tools) so the caller can degrade — every
   * transport failure throws 503 instead.
   */
  private async openStreamWithMessages(
    messages: Array<Record<string, unknown>>,
    input: ChatCompletionInput,
    tools: ChatTool[] | undefined,
    modelName: string = this.model,
  ): Promise<ReadableStream<Uint8Array> | null> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'text/event-stream',
          ...(this.apiKey ? { Authorization: `Bearer ${this.apiKey}` } : {}),
        },
        body: JSON.stringify({
          model: modelName,
          messages,
          max_tokens: input.maxTokens,
          temperature: input.temperature,
          stream: true,
          ...this.thinkingParams(input.thinking),
          ...(tools && tools.length > 0
            ? { tools, tool_choice: 'auto' }
            : {}),
        }),
        signal: controller.signal,
      });
      if (response.status === 400 && tools !== undefined) return null;
      if (response.status === 404 && modelName !== this.fallbackModel && this.fallbackModel) {
        logger.warn({ primary: modelName, fallback: this.fallbackModel }, 'Model 404, falling back in stream');
        return await this.openStreamWithMessages(messages, input, tools, this.fallbackModel);
      }
      if (response.status === 429) {
        throw new ServiceUnavailableError(
          'The local AI model is overloaded, please retry later.',
        );
      }
      if (!response.ok || !response.body) {
        logger.error({ status: response.status }, 'AI gateway stream error');
        throw new InternalError('Course generation failed on the AI gateway.');
      }
      return response.body;
    } catch (error) {
      if (
        error instanceof ServiceUnavailableError ||
        error instanceof InternalError
      ) {
        throw error;
      }
      logger.warn({ err: error }, 'AI gateway stream unreachable');
      throw new ServiceUnavailableError(
        'The local AI model is currently unreachable. Start Ollama and retry.',
      );
    } finally {
      clearTimeout(timer);
    }
  }

  private openStream(
    input: ChatCompletionInput,
    tools: ChatTool[] | undefined,
    modelName: string = this.model,
  ): Promise<ReadableStream<Uint8Array> | null> {
    const messages = [
      { role: 'system', content: input.system },
      { role: 'user', content: input.user },
    ];
    return this.openStreamWithMessages(messages, input, tools, modelName);
  }

  private async consumeStream(
    stream: ReadableStream<Uint8Array>,
    onDelta: (delta: string) => void,
  ): Promise<StreamCompletionUsage> {
    let promptTokens: number | null = null;
    let completionTokens: number | null = null;
    let model = this.model;
    let buffer = '';
    // Stall visibility: the local model can stay silent for minutes while
    // thinking or running server-side tools (no text frames at all). A
    // parallel timer logs every 90 s of silence so `docker logs api` shows
    // whether the request is stuck server-side instead of failing
    // silently client-side.
    let lastFrameAt = Date.now();
    const stallTimer = setInterval(() => {
      const silentSec = Math.round((Date.now() - lastFrameAt) / 1000);
      if (silentSec >= 90) {
        logger.warn(
          { silentSec, promptTokens },
          'AI stream silent for 90 s+ (model thinking or server-side tools running?)',
        );
        lastFrameAt = Date.now();
      }
    }, 15_000);
    // Node keeps running while a timer is pending: don't hold the process.
    stallTimer.unref?.();
    const decoder = new TextDecoder();
    try {
      for await (const chunk of stream as AsyncIterable<Uint8Array>) {
        buffer += decoder.decode(chunk, { stream: true });
        const lines = buffer.split('\n');
        buffer = lines.pop() ?? '';
        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed.startsWith('data:')) continue;
          lastFrameAt = Date.now();
          const payload = trimmed.slice('data:'.length).trim();
          if (payload === '[DONE]') continue;
          let frame: {
            choices?: Array<{ delta?: { content?: unknown } }>;
            usage?: { prompt_tokens?: number; completion_tokens?: number };
            model?: string;
          };
          try {
            frame = JSON.parse(payload) as typeof frame;
          } catch {
            continue;
          }
          if (typeof frame.model === 'string') model = frame.model;
          if (frame.usage) {
            promptTokens = frame.usage.prompt_tokens ?? promptTokens;
            completionTokens = frame.usage.completion_tokens ?? completionTokens;
          }
          const delta = frame.choices?.[0]?.delta?.content;
          if (typeof delta === 'string' && delta.length > 0) onDelta(delta);
        }
      }
    } finally {
      clearInterval(stallTimer);
    }
    return { promptTokens, completionTokens, model };
  }

  public async checkHealth(): Promise<AiGatewayStatus> {
    const startedAt = Date.now();
    try {
      const controller = new AbortController();
      const timer = setTimeout(() => controller.abort(), this.statusTimeoutMs);
      let detectedModel = this.model;
      try {
        // Ollama may require the API key even on GET /v1/models.
        const response = await fetch(`${this.baseUrl}/v1/models`, {
          headers: {
            ...(this.apiKey ? { Authorization: `Bearer ${this.apiKey}` } : {}),
          },
          signal: controller.signal,
        });
        if (!response.ok) {
          return { available: false, model: this.model, latencyMs: null };
        }
        const body = (await response.json().catch(() => null)) as { data?: Array<{ id: string }> } | null;
        if (body?.data && Array.isArray(body.data)) {
          // Ignore embedding-only models (e.g. embeddinggemma-2) so the
          // "gemma" substring can never be mistaken for a chat model.
          const ids = body.data
            .map((m) => m.id)
            .filter((id) => !id.toLowerCase().includes('embedding'));
          const normalize = (id: string): string => id.replace(/:latest$/, '');
          const primary = ids.find((id) => normalize(id) === normalize(this.model));
          const fallback = ids.find((id) => normalize(id) === normalize(this.fallbackModel));
          if (primary) {
            detectedModel = primary;
          } else if (fallback) {
            detectedModel = fallback;
          } else if (ids[0]) {
            detectedModel = ids[0];
          }
        }
      } finally {
        clearTimeout(timer);
      }
      return { available: true, model: detectedModel, latencyMs: Date.now() - startedAt };
    } catch {
      return { available: false, model: this.model, latencyMs: null };
    }
  }
}
