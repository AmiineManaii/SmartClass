export type GenerateMode = 'topic' | 'text' | 'url' | 'pdf';

export type GenerateLevel = 'concis' | 'equilibre' | 'detaille';

export type GenerateDifficulty = 'facile' | 'moyen' | 'difficile';

export type GenerateFormat = 'resume' | 'flashcards' | 'carte-mentale';

export interface GenerateExtras {
  /** Worked simple examples in every section. */
  examples: boolean;
  /** Figures and graphs as mermaid code blocks. */
  mermaid: boolean;
  /** Illustrations from the web (image URLs from search results only). */
  webImages: boolean;
  /**
   * Teacher-chosen web tooling (web_search, fetch_url, execute_code,
   * calculator). Each server-side tool round trip delays the first visible
   * token, so this defaults OFF in the mobile UI.
   */
  webSearch: boolean;
  /**
   * Teacher-chosen chain-of-thought. The silent thinking phase delays the
   * first visible token, so this defaults OFF in the mobile UI (recommended
   * for cours complet / difficile).
   */
  thinking: boolean;
  /**
   * Local AI image generation via ComfyUI Desktop. When enabled, the model
   * can generate custom illustrations on the teacher's GPU.
   */
  generateImages: boolean;
}

export interface ChatTool {
  type: 'function';
  function: {
    name: string;
    description: string;
    parameters: Record<string, unknown>;
  };
}

export interface ChatCompletionInput {
  system: string;
  user: string;
  maxTokens: number;
  temperature: number;
  tools?: ChatTool[];
  /**
   * Chain-of-thought on the local model. Expensive (long silent thinking
   * phase before the first visible token): reserve for demanding
   * generations. Defaults to `AI_ENABLE_THINKING` when omitted.
   */
  thinking?: boolean;
}

export interface ChatCompletionResult {
  content: string;
  promptTokens: number | null;
  completionTokens: number | null;
  model: string;
  toolsUsed: boolean;
}

export interface StreamCompletionUsage {
  promptTokens: number | null;
  completionTokens: number | null;
  model: string;
}

export interface AiGatewayStatus {
  available: boolean;
  model: string;
  latencyMs: number | null;
}

export interface AiGatewayPort {
  chatCompletion(input: ChatCompletionInput): Promise<ChatCompletionResult>;
  /**
   * Server-sent streaming: invokes `onDelta` for every text chunk and
   * resolves with usage once the `[DONE]` frame arrives. Used to show
   * live progress on long local generations (2-4 min at ~12 tok/s).
   */
  streamCompletion(
    input: ChatCompletionInput,
    onDelta: (delta: string) => void,
  ): Promise<StreamCompletionUsage>;
  checkHealth(): Promise<AiGatewayStatus>;
}
