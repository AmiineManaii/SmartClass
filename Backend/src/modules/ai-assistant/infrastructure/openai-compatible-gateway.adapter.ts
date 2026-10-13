import { getEnv } from '../../../config/env.js';
import {
  InternalError,
  ServiceUnavailableError,
} from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import { COURSE_TOOL_NAMES } from '../domain/ai-tools.js';
import type {
  AiGatewayPort,
  AiGatewayStatus,
  ChatCompletionInput,
  ChatCompletionResult,
  ChatTool,
  StreamCompletionUsage,
} from '../domain/ai-gateway.port.js';

interface ChatCompletionsBody {
  choices?: Array<{
    message?: { content?: unknown };
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

export class OpenAICompatibleGateway implements AiGatewayPort {
  private readonly baseUrl: string;
  private readonly model: string;
  private readonly apiKey: string;
  private readonly timeoutMs: number;
  private readonly statusTimeoutMs: number;

  constructor(params?: {
    baseUrl?: string;
    model?: string;
    apiKey?: string;
    timeoutMs?: number;
    statusTimeoutMs?: number;
  }) {
    const env = getEnv();
    this.baseUrl = (params?.baseUrl ?? env.AI_BASE_URL).replace(/\/+$/, '');
    this.model = params?.model ?? env.AI_MODEL;
    this.apiKey = params?.apiKey ?? env.AI_API_KEY;
    this.timeoutMs = params?.timeoutMs ?? env.AI_TIMEOUT_MS;
    this.statusTimeoutMs = params?.statusTimeoutMs ?? env.AI_STATUS_TIMEOUT_MS;
  }

  /**
   * Unsloth execution flags: chain-of-thought, server-side tool running
   * (`tool_servers` + `auto_execute_tools` + `permission_mode: 'off'` —
   * Unsloth refuses tool calls without it: "confirm_tool_calls requires
   * ... set permission_mode to 'off' to run tools without confirmation")
   * and iteration budget. Plain OpenAI-compatible servers ignore unknown
   * fields. The thinking flag is sent on EVERY request (not just tool
   * ones) so cheap generations can skip the silent thinking phase.
   */
  private unslothParams(thinking: boolean | undefined, withTools: boolean): Record<string, unknown> {
    const env = getEnv();
    return {
      chat_template_kwargs: { enable_thinking: thinking ?? env.AI_ENABLE_THINKING },
      ...(withTools
        ? {
            enable_tools: true,
            tool_servers: COURSE_TOOL_NAMES,
            auto_execute_tools: true,
            permission_mode: env.AI_PERMISSION_MODE,
            max_tool_iterations: env.AI_MAX_TOOL_ITERATIONS,
          }
        : {}),
    };
  }

  /** Unsloth needs this header for server-side tool execution streams. */
  private unslothHeaders(hasTools: boolean): Record<string, string> {
    return hasTools ? { 'X-Unsloth-Events': '1' } : {};
  }

  private async postCompletions(
    input: ChatCompletionInput,
    tools: ChatTool[] | undefined,
    timeoutMs: number,
  ): Promise<ChatCompletionsBody & { httpStatus: number }> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    try {
      const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          ...this.unslothHeaders(!!(tools && tools.length > 0)),
          ...(this.apiKey ? { Authorization: `Bearer ${this.apiKey}` } : {}),
        },
        body: JSON.stringify({
          model: this.model,
          messages: [
            { role: 'system', content: input.system },
            { role: 'user', content: input.user },
          ],
          max_tokens: input.maxTokens,
          temperature: input.temperature,
          ...this.unslothParams(input.thinking, !!(tools && tools.length > 0)),
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

  public async chatCompletion(input: ChatCompletionInput): Promise<ChatCompletionResult> {
    const tools = input.tools && input.tools.length > 0 ? input.tools : undefined;

    let raw = await this.postOrThrow(input, tools);
    let toolsUsed = tools !== undefined;

    // The local server may not support tool calling (400): degrade
    // gracefully by retrying the same prompt without tools.
    if (raw.httpStatus === 400 && tools !== undefined) {
      logger.info('AI gateway rejected tools, retrying without them');
      toolsUsed = false;
      raw = await this.postOrThrow(input, undefined);
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

    const content = extractText(raw.choices?.[0]?.message?.content).trim();
    if (!content) {
      logger.error('AI gateway returned an empty completion');
      throw new InternalError('Course generation returned an empty result.');
    }

    return {
      content,
      promptTokens: raw.usage?.prompt_tokens ?? null,
      completionTokens: raw.usage?.completion_tokens ?? null,
      model: raw.model ?? this.model,
      toolsUsed,
    };
  }

  private async postOrThrow(
    input: ChatCompletionInput,
    tools: ChatTool[] | undefined,
  ): Promise<ChatCompletionsBody & { httpStatus: number }> {
    try {
      return await this.postCompletions(input, tools, this.timeoutMs);
    } catch (error) {
      logger.warn({ err: error }, 'AI gateway unreachable');
      throw new ServiceUnavailableError(
        'The local AI model is currently unreachable. Start it in Unsloth Desktop and retry.',
      );
    }
  }

  public async streamCompletion(
    input: ChatCompletionInput,
    onDelta: (delta: string) => void,
  ): Promise<StreamCompletionUsage> {
    const tools = input.tools && input.tools.length > 0 ? input.tools : undefined;
    const events = await this.openStream(input, tools);
    let stream = events;
    if (stream === null) {
      // The local server may not support tool calling (400): degrade
      // gracefully by retrying the same prompt without tools.
      logger.info('AI gateway rejected tools, retrying stream without them');
      stream = await this.openStream(input, undefined);
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
  private async openStream(
    input: ChatCompletionInput,
    tools: ChatTool[] | undefined,
  ): Promise<ReadableStream<Uint8Array> | null> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await fetch(`${this.baseUrl}/v1/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Accept: 'text/event-stream',
          ...this.unslothHeaders(!!(tools && tools.length > 0)),
          ...(this.apiKey ? { Authorization: `Bearer ${this.apiKey}` } : {}),
        },
        body: JSON.stringify({
          model: this.model,
          messages: [
            { role: 'system', content: input.system },
            { role: 'user', content: input.user },
          ],
          max_tokens: input.maxTokens,
          temperature: input.temperature,
          stream: true,
          ...this.unslothParams(input.thinking, !!(tools && tools.length > 0)),
          ...(tools && tools.length > 0
            ? { tools, tool_choice: 'auto' }
            : {}),
        }),
        signal: controller.signal,
      });
      if (response.status === 400 && tools !== undefined) return null;
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
        'The local AI model is currently unreachable. Start it in Unsloth Desktop and retry.',
      );
    } finally {
      clearTimeout(timer);
    }
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
      try {
        // Unsloth requires the API key even on GET /v1/models.
        const response = await fetch(`${this.baseUrl}/v1/models`, {
          headers: {
            ...(this.apiKey ? { Authorization: `Bearer ${this.apiKey}` } : {}),
          },
          signal: controller.signal,
        });
        if (!response.ok) {
          return { available: false, model: this.model, latencyMs: null };
        }
        // Drain the body so sockets are reused.
        await response.arrayBuffer().catch(() => null);
      } finally {
        clearTimeout(timer);
      }
      return { available: true, model: this.model, latencyMs: Date.now() - startedAt };
    } catch {
      return { available: false, model: this.model, latencyMs: null };
    }
  }
}
