import { getEnv } from '../../../config/env.js';
import type { Role } from '../../auth/index.js';
import type {
  AiGatewayPort,
  GenerateDifficulty,
  GenerateExtras,
  GenerateFormat,
  GenerateLevel,
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
import type {
  KnowledgeGroundingOptions,
  KnowledgeGroundingSearchMode,
  KnowledgeSourceAttribution,
} from '../domain/knowledge-grounding.types.js';
import type { PdfTextExtractorPort } from '../infrastructure/pdf-text-extractor.adapter.js';
import type { CourseKnowledgeGroundingService } from './course-knowledge-grounding.service.js';
import { extrasForMode } from './generate-course.use-case.js';

const PDF_GROUNDING_MAX_CHARS = 5000;

export interface ImprovePdfDTO {
  file: { buffer: Buffer; originalName: string; size: number };
  level: GenerateLevel;
  difficulty?: GenerateDifficulty;
  extras?: Partial<GenerateExtras>;
  format: GenerateFormat;
  outline?: CourseOutline;
  requesterId?: string;
  requesterRole?: Role | null;
  knowledge?: KnowledgeGroundingOptions;
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
  knowledgeSources: KnowledgeSourceAttribution[];
  knowledgeSearchMode: KnowledgeGroundingSearchMode;
  knowledgeDegradedReason: string | null;
}

export class ImprovePdfUseCase {
  constructor(
    private readonly extractor: PdfTextExtractorPort,
    private readonly gateway: AiGatewayPort,
    private readonly grounding?: CourseKnowledgeGroundingService,
  ) {}

  public async execute(dto: ImprovePdfDTO): Promise<ImprovePdfResult> {
    const env = getEnv();
    const { text, totalPages } = await this.extractor.extract(dto.file.buffer);
    const grounded = this.grounding
      ? await this.grounding.resolve({
          requesterId: dto.requesterId,
          requesterRole: dto.requesterRole,
          query: [
            dto.file.originalName.replace(/\.[^/.]+$/, ''),
            dto.outline?.title,
            text.slice(0, 1000),
          ]
            .filter(Boolean)
            .join('\n'),
          options: dto.knowledge,
          maxChars: PDF_GROUNDING_MAX_CHARS,
        })
      : {
          promptContext: '',
          sources: [],
          searchMode: 'DISABLED' as const,
          degradedReason: null,
        };

    const truncatedSource = text.length > env.AI_MAX_SOURCE_CHARS;
    const difficulty: GenerateDifficulty = dto.difficulty ?? 'moyen';
    const extras: GenerateExtras = extrasForMode('text', dto.extras);
    const toolsOffered = shouldOfferTools({
      webSearch: extras.webSearch,
      webImages: extras.webImages,
      generateImages: extras.generateImages,
      webSearchEnabled: env.AI_ENABLE_WEB_SEARCH,
    });
    const sourceSlice = truncatedSource ? text.slice(0, env.AI_MAX_SOURCE_CHARS) : text;
    const knowledgeContext = grounded.promptContext || undefined;
    const prompt = dto.outline
      ? buildCourseFromOutlinePrompt({
          outline: dto.outline,
          level: dto.level,
          difficulty,
          extras,
          format: dto.format,
          toolsOffered,
          sourceText: sourceSlice,
          knowledgeContext,
        })
      : buildCoursePrompt({
          mode: 'text',
          level: dto.level,
          difficulty,
          extras,
          format: dto.format,
          sourceText: sourceSlice,
          toolsOffered,
          knowledgeContext,
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
      knowledgeSources: grounded.sources,
      knowledgeSearchMode: grounded.searchMode,
      knowledgeDegradedReason: grounded.degradedReason,
    };
  }

  /**
   * Streaming variant: same extraction and prompt, deltas forwarded live
   * to `onDelta`, final metadata resolved at `[DONE]`. `onPhase` reports
   * pipeline progress (`extracting` → `knowledge` → `generating`) so clients
   * can tell a long PDF parse / RAG lookup apart from model silence.
   */
  public async stream(
    dto: ImprovePdfDTO,
    onDelta: (delta: string) => void,
    onPhase?: (phase: string) => void,
  ): Promise<Omit<ImprovePdfResult, 'content'>> {
    const env = getEnv();
    const { text, totalPages } = await this.extractor.extract(dto.file.buffer);
    const willSearchKnowledge = Boolean(
      this.grounding && dto.requesterId && dto.knowledge?.enabled !== false,
    );
    if (willSearchKnowledge) {
      onPhase?.('knowledge');
    }
    const grounded = this.grounding
      ? await this.grounding.resolve({
          requesterId: dto.requesterId,
          requesterRole: dto.requesterRole,
          query: [
            dto.file.originalName.replace(/\.[^/.]+$/, ''),
            dto.outline?.title,
            text.slice(0, 1000),
          ]
            .filter(Boolean)
            .join('\n'),
          options: dto.knowledge,
          maxChars: PDF_GROUNDING_MAX_CHARS,
        })
      : {
          promptContext: '',
          sources: [],
          searchMode: 'DISABLED' as const,
          degradedReason: null,
        };

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
    const sourceSlice = truncatedSource ? text.slice(0, env.AI_MAX_SOURCE_CHARS) : text;
    const knowledgeContext = grounded.promptContext || undefined;
    const prompt = dto.outline
      ? buildCourseFromOutlinePrompt({
          outline: dto.outline,
          level: dto.level,
          difficulty,
          extras,
          format: dto.format,
          toolsOffered,
          sourceText: sourceSlice,
          knowledgeContext,
        })
      : buildCoursePrompt({
          mode: 'text',
          level: dto.level,
          difficulty,
          extras,
          format: dto.format,
          sourceText: sourceSlice,
          toolsOffered,
          knowledgeContext,
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
      knowledgeSources: grounded.sources,
      knowledgeSearchMode: grounded.searchMode,
      knowledgeDegradedReason: grounded.degradedReason,
    };
  }
}
