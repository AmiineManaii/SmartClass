import { getEnv } from '../../../config/env.js';
import { AiModelUnavailableError } from '../../../shared/errors/app-error.js';
import type { ExamAiModelCatalogPort } from '../domain/exam-ai-model-catalog.port.js';

interface OllamaTagsResponse {
  models?: Array<{ name?: string; model?: string }>;
}

/** Reads `/api/tags` from the local Ollama server. Read-only by design. */
export class OllamaExamModelCatalogAdapter implements ExamAiModelCatalogPort {
  private readonly baseUrl: string;
  private readonly timeoutMs: number;

  constructor(params?: { baseUrl?: string; timeoutMs?: number }) {
    const env = getEnv();
    this.baseUrl = (params?.baseUrl ?? env.AI_BASE_URL).replace(/\/+$/, '');
    this.timeoutMs = params?.timeoutMs ?? env.AI_STATUS_TIMEOUT_MS;
  }

  public async listInstalledModels(): Promise<string[]> {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), this.timeoutMs);
    try {
      const response = await fetch(`${this.baseUrl}/api/tags`, { signal: controller.signal });
      if (!response.ok) {
        throw new AiModelUnavailableError(
          `Ollama responded with HTTP ${response.status}. Start Ollama and retry.`,
        );
      }
      const body = (await response.json().catch(() => null)) as OllamaTagsResponse | null;
      return (body?.models ?? [])
        .map((model) => model.name ?? model.model ?? '')
        .filter((name) => name.length > 0);
    } catch (error) {
      if (error instanceof AiModelUnavailableError) throw error;
      throw new AiModelUnavailableError(
        'The local Ollama server is unreachable. Start Ollama and retry.',
      );
    } finally {
      clearTimeout(timer);
    }
  }
}
