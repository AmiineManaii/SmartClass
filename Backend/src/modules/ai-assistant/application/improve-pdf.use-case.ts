import { getEnv } from '../../../config/env.js';
import type {
  AiGatewayPort,
  GenerateDifficulty,
  GenerateExtras,
  GenerateFormat,
  GenerateLevel,
} from '../domain/ai-gateway.port.js';
import { COURSE_TOOLS } from '../domain/ai-tools.js';
import { buildCoursePrompt, COURSE_PROMPT_VERSION, maxTokensForLevel, shouldOfferTools } from '../domain/course-prompt.js';
import type { PdfTextExtractorPort } from '../infrastructure/pdf-text-extractor.adapter.js';
import { extrasForMode } from './generate-course.use-case.js';

export interface ImprovePdfDTO {
  file: { buffer: Buffer; originalName: string; size: number };
  level: GenerateLevel;
  difficulty?: GenerateDifficulty;
  extras?: Partial<GenerateExtras>;
  format: GenerateFormat;
}

export interface ImprovePdfResult {
  content: string;
  level: GenerateLevel;
  difficulty: GenerateDifficulty;
  format: GenerateFormat;
  model: string;
  promptVersion: string;
  fileName: string;
  totalPages: number;
  truncatedSource: boolean;
  sourceChars: number;
  toolsUsed: boolean;
  usage: { promptTokens: number | null; completionTokens: number | null };
}

export class ImprovePdfUseCase {
  constructor(
    private readonly extractor: PdfTextExtractorPort,
    private readonly gateway: AiGatewayPort,
  ) {}

  public async execute(dto: ImprovePdfDTO): Promise<ImprovePdfResult> {
    const env = getEnv();
    const { text, totalPages } = await this.extractor.extract(dto.file.buffer);

    const truncatedSource = text.length > env.AI_MAX_SOURCE_CHARS;
    const difficulty: GenerateDifficulty = dto.difficulty ?? 'moyen';
    const extras: GenerateExtras = extrasForMode('text', dto.extras);
    const toolsOffered = shouldOfferTools({
      webSearch: extras.webSearch,
      webImages: extras.webImages,
      generateImages: extras.generateImages,
      webSearchEnabled: env.AI_ENABLE_WEB_SEARCH,
    });
    const prompt = buildCoursePrompt({
      mode: 'text',
      level: dto.level,
      difficulty,
      extras,
      format: dto.format,
      sourceText: truncatedSource ? text.slice(0, env.AI_MAX_SOURCE_CHARS) : text,
      toolsOffered,
    });

    const completion = await this.gateway.chatCompletion({
      system: prompt.system,
      user: prompt.user,
      maxTokens: maxTokensForLevel(dto.level, env.AI_MAX_TOKENS),
      temperature: env.AI_TEMPERATURE,
      tools: toolsOffered ? COURSE_TOOLS : undefined,
      thinking: extras.thinking,
    });

    return {
      content: completion.content,
      level: dto.level,
      difficulty,
      format: dto.format,
      model: completion.model,
      promptVersion: COURSE_PROMPT_VERSION,
      fileName: dto.file.originalName,
      totalPages,
      truncatedSource,
      sourceChars: text.length,
      toolsUsed: completion.toolsUsed,
      usage: {
        promptTokens: completion.promptTokens,
        completionTokens: completion.completionTokens,
      },
    };
  }

  /**
   * Streaming variant: same extraction and prompt, deltas forwarded live
   * to `onDelta`, final metadata resolved at `[DONE]`. `onPhase` reports
   * pipeline progress (`extracting` → `generating`) so clients can tell a
   * long PDF parse apart from model silence.
   */
  public async stream(
    dto: ImprovePdfDTO,
    onDelta: (delta: string) => void,
    onPhase?: (phase: string) => void,
  ): Promise<Omit<ImprovePdfResult, 'content'>> {
    const env = getEnv();
    const { text, totalPages } = await this.extractor.extract(dto.file.buffer);

    onPhase?.('generating');
    const truncatedSource = text.length > env.AI_MAX_SOURCE_CHARS;
    const difficulty: GenerateDifficulty = dto.difficulty ?? 'moyen';
    const extras: GenerateExtras = extrasForMode('text', dto.extras);
    const toolsOffered = shouldOfferTools({
      webSearch: extras.webSearch,
      webImages: extras.webImages,
      generateImages: extras.generateImages,
      webSearchEnabled: env.AI_ENABLE_WEB_SEARCH,
    });
    const prompt = buildCoursePrompt({
      mode: 'text',
      level: dto.level,
      difficulty,
      extras,
      format: dto.format,
      sourceText: truncatedSource ? text.slice(0, env.AI_MAX_SOURCE_CHARS) : text,
      toolsOffered,
    });
    const usage = await this.gateway.streamCompletion(
      {
        system: prompt.system,
        user: prompt.user,
        maxTokens: maxTokensForLevel(dto.level, env.AI_MAX_TOKENS),
        temperature: env.AI_TEMPERATURE,
        tools: toolsOffered ? COURSE_TOOLS : undefined,
        thinking: extras.thinking,
      },
      onDelta,
    );

    return {
      level: dto.level,
      difficulty,
      format: dto.format,
      model: usage.model,
      promptVersion: COURSE_PROMPT_VERSION,
      fileName: dto.file.originalName,
      totalPages,
      truncatedSource,
      sourceChars: text.length,
      toolsUsed: toolsOffered,
      usage: {
        promptTokens: usage.promptTokens,
        completionTokens: usage.completionTokens,
      },
    };
  }
}
