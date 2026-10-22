import { getEnv } from '../../../config/env.js';
import { ValidationError } from '../../../shared/errors/app-error.js';
import type {
  AiGatewayPort,
  GenerateDifficulty,
  GenerateExtras,
  GenerateFormat,
  GenerateLevel,
  GenerateMode,
} from '../domain/ai-gateway.port.js';
import { COURSE_TOOLS } from '../domain/ai-tools.js';
import {
  buildCourseFromOutlinePrompt,
  buildCoursePrompt,
  COURSE_PROMPT_VERSION,
  maxTokensForLevel,
  shouldOfferTools,
  type CourseOutline,
} from '../domain/course-prompt.js';
import type { UrlFetcherPort } from '../domain/url-fetcher.port.js';

export const DEFAULT_EXTRAS: GenerateExtras = {
  examples: true,
  mermaid: true,
  webImages: false,
  webSearch: false,
  thinking: false,
  generateImages: false,
};

/**
 * Source-aware defaults:
 * - URL import enriches the fetched page with fresh web results.
 * - An old PDF/notes needs reasoning to restructure it and web search to
 *   fill what the document is missing.
 * Explicit caller values still win, so a teacher can turn either off.
 */
export const extrasForMode = (
  mode: GenerateMode,
  extras?: Partial<GenerateExtras>,
): GenerateExtras => {
  const sourceDefaults: Partial<GenerateExtras> =
    mode === 'url'
      ? { webSearch: true }
      : mode === 'text'
        ? { thinking: true, webSearch: true }
        : {};
  return { ...DEFAULT_EXTRAS, ...sourceDefaults, ...extras };
};

export interface GenerateCourseDTO {
  mode: GenerateMode;
  level: GenerateLevel;
  difficulty?: GenerateDifficulty;
  extras?: Partial<GenerateExtras>;
  format: GenerateFormat;
  subject?: string;
  sourceText?: string;
  url?: string;
  outline?: CourseOutline;
}

export interface GenerateCourseResult {
  content: string;
  mode: GenerateMode;
  level: GenerateLevel;
  difficulty: GenerateDifficulty;
  format: GenerateFormat;
  model: string;
  promptVersion: string;
  truncatedSource: boolean;
  sourceChars: number;
  toolsUsed: boolean;
  usage: { promptTokens: number | null; completionTokens: number | null };
}

export class GenerateCourseUseCase {
  constructor(
    private readonly gateway: AiGatewayPort,
    private readonly urlFetcher: UrlFetcherPort,
  ) {}

  public async execute(dto: GenerateCourseDTO): Promise<GenerateCourseResult> {
    const env = getEnv();
    const prepared = await this.prepare(dto);
    const prompt = prepared.outline
      ? buildCourseFromOutlinePrompt({
          outline: prepared.outline,
          level: prepared.level,
          difficulty: prepared.difficulty,
          extras: prepared.extras,
          format: prepared.format,
          toolsOffered: prepared.toolsOffered,
        })
      : buildCoursePrompt(prepared);

    const completion = await this.gateway.chatCompletion({
      system: prompt.system,
      user: prompt.user,
      // Budget par niveau : court 8K, normal 20K, complet 32K (plafonné
      // par AI_MAX_TOKENS pour les petits contextes locaux).
      maxTokens: maxTokensForLevel(prepared.level, env.AI_MAX_TOKENS),
      temperature: env.AI_TEMPERATURE,
      // Outils seulement quand utiles : chaque appel d'outil retarde le
        // premier token visible de 20 s+ côté Ollama.
      tools: prepared.toolsOffered ? COURSE_TOOLS : undefined,
      // Thinking réservé aux générations exigeantes (longues ou challenge).
      thinking: prepared.extras.thinking,
    });

    return {
      content: completion.content,
      mode: prepared.mode,
      level: prepared.level,
      difficulty: prepared.difficulty,
      format: dto.format,
      model: completion.model,
      promptVersion: COURSE_PROMPT_VERSION,
      truncatedSource: prepared.truncatedSource,
      sourceChars: prepared.sourceChars,
      toolsUsed: completion.toolsUsed,
      usage: {
        promptTokens: completion.promptTokens,
        completionTokens: completion.completionTokens,
      },
    };
  }

  /**
   * Streaming variant: same validation and prompt, deltas forwarded live
   * to `onDelta`, final metadata (model, usage, prompt version) resolved
   * at `[DONE]`. The controller relays both as SSE frames.
   */
  public async stream(
    dto: GenerateCourseDTO,
    onDelta: (delta: string) => void,
  ): Promise<Omit<GenerateCourseResult, 'content'>> {
    const env = getEnv();
    const prepared = await this.prepare(dto);
    const prompt = prepared.outline
      ? buildCourseFromOutlinePrompt({
          outline: prepared.outline,
          level: prepared.level,
          difficulty: prepared.difficulty,
          extras: prepared.extras,
          format: prepared.format,
          toolsOffered: prepared.toolsOffered,
        })
      : buildCoursePrompt(prepared);

    const usage = await this.gateway.streamCompletion(
      {
        system: prompt.system,
        user: prompt.user,
        maxTokens: maxTokensForLevel(prepared.level, env.AI_MAX_TOKENS),
        temperature: env.AI_TEMPERATURE,
        tools: prepared.toolsOffered ? COURSE_TOOLS : undefined,
        thinking: prepared.extras.thinking,
      },
      onDelta,
    );

    return {
      mode: prepared.mode,
      level: prepared.level,
      difficulty: prepared.difficulty,
      format: dto.format,
      model: usage.model,
      promptVersion: COURSE_PROMPT_VERSION,
      truncatedSource: prepared.truncatedSource,
      sourceChars: prepared.sourceChars,
      toolsUsed: prepared.toolsOffered,
      usage: {
        promptTokens: usage.promptTokens,
        completionTokens: usage.completionTokens,
      },
    };
  }

  private async prepare(dto: GenerateCourseDTO): Promise<{
    mode: GenerateMode;
    level: GenerateLevel;
    difficulty: GenerateDifficulty;
    extras: GenerateExtras;
    format: GenerateFormat;
    subject?: string;
    sourceText?: string;
    sourceUrl: string | null;
    toolsOffered: boolean;
    truncatedSource: boolean;
    sourceChars: number;
    outline?: CourseOutline;
  }> {
    const env = getEnv();
    let subject = dto.subject?.trim() || dto.outline?.title?.trim() || undefined;
    let sourceText = dto.sourceText?.trim() || undefined;
    let sourceUrl: string | null = null;

    if (dto.mode === 'topic') {
      if (!subject || (dto.outline ? subject.length < 3 : subject.length < 10)) {
        throw new ValidationError('A subject of at least 10 characters is required', [
          { path: 'subject', message: 'Describe the course subject (min 10 characters)' },
        ]);
      }
    }

    if (dto.mode === 'url') {
      if (!dto.url) {
        throw new ValidationError('A link is required', [
          { path: 'url', message: 'Provide the source link' },
        ]);
      }
      const fetched = await this.urlFetcher.fetchText(dto.url);
      sourceUrl = fetched.finalUrl;
      const headed = fetched.title ? `${fetched.title}\n\n` : '';
      sourceText = `${headed}${fetched.text}`.trim();
      if (!subject && fetched.title) subject = fetched.title;
    }

    if ((dto.mode === 'text' || dto.mode === 'url') && (!sourceText || sourceText.length < 100)) {
      throw new ValidationError('Source content is too short', [
        {
          path: dto.mode === 'url' ? 'url' : 'sourceText',
          message: 'At least 100 characters of source content are required',
        },
      ]);
    }

    const truncatedSource = (sourceText?.length ?? 0) > env.AI_MAX_SOURCE_CHARS;
    const difficulty = dto.difficulty ?? 'moyen';
    const extras = extrasForMode(dto.mode, dto.extras);
    return {
      mode: dto.mode,
      level: dto.level,
      difficulty,
      extras,
      format: dto.format,
      subject,
      sourceText: truncatedSource ? sourceText!.slice(0, env.AI_MAX_SOURCE_CHARS) : sourceText,
      sourceUrl,
      toolsOffered: shouldOfferTools({
        webSearch: extras.webSearch,
        webImages: extras.webImages,
        generateImages: extras.generateImages,
        webSearchEnabled: env.AI_ENABLE_WEB_SEARCH,
      }),
      truncatedSource,
      sourceChars: sourceText?.length ?? 0,
    };
  }
}
