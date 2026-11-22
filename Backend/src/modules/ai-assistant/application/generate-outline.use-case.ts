import { InternalError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { AiGatewayPort, GenerateDifficulty, GenerateLevel } from '../domain/ai-gateway.port.js';
import {
  buildOutlinePrompt,
  type CourseOutline,
} from '../domain/course-prompt.js';
import type {
  KnowledgeGroundingOptions,
  KnowledgeGroundingSearchMode,
  KnowledgeSourceAttribution,
} from '../domain/knowledge-grounding.types.js';
import type { CourseKnowledgeGroundingService } from './course-knowledge-grounding.service.js';

export interface GenerateOutlineInput {
  topic?: string;
  subject?: string;
  level?: GenerateLevel;
  difficulty?: GenerateDifficulty;
  sourceContext?: string;
  sourceText?: string;
  requesterId?: string;
  requesterRole?: Role | null;
  knowledge?: KnowledgeGroundingOptions;
}

export interface GenerateOutlineResult {
  outline: CourseOutline;
  model: string;
  knowledgeSources: KnowledgeSourceAttribution[];
  knowledgeSearchMode: KnowledgeGroundingSearchMode;
  knowledgeDegradedReason: string | null;
}

const OUTLINE_GROUNDING_MAX_CHARS = 3500;

const parseOutlineJson = (content: string, defaultTopic: string): CourseOutline => {
  // Strip ```json and ``` if wrapped
  let cleaned = content.trim();
  const jsonMatch = cleaned.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
  if (jsonMatch && jsonMatch[1]) {
    cleaned = jsonMatch[1].trim();
  }

  try {
    const parsed = JSON.parse(cleaned) as Record<string, unknown>;
    const title = typeof parsed.title === 'string' && parsed.title.trim().length > 0
      ? parsed.title.trim()
      : defaultTopic;
    const targetAudience = typeof parsed.targetAudience === 'string' ? parsed.targetAudience : 'Étudiants universitaires';
    const prerequisites = Array.isArray(parsed.prerequisites) ? parsed.prerequisites.map(String) : [];
    const rawSections = Array.isArray(parsed.sections) ? parsed.sections : [];

    const sections = rawSections.map((sec, idx) => {
      const s = typeof sec === 'object' && sec !== null ? (sec as Record<string, unknown>) : {};
      return {
        id: typeof s.id === 'string' && s.id.length > 0 ? s.id : `sec-${idx + 1}`,
        title: typeof s.title === 'string' && s.title.length > 0 ? s.title : `Partie ${idx + 1}`,
        description: typeof s.description === 'string' ? s.description : '',
        keyTopics: Array.isArray(s.keyTopics) ? s.keyTopics.map(String) : [],
        estimatedMinutes: typeof s.estimatedMinutes === 'number' ? s.estimatedMinutes : 15,
      };
    });

    if (sections.length === 0) {
      throw new Error('No sections generated');
    }

    return {
      title,
      targetAudience,
      prerequisites,
      sections,
    };
  } catch {
    // Fallback if model output isn't strict JSON: split by lines/headers
    const lines = content.split('\n').filter((l) => l.trim().length > 0);
    const fallbackSections = lines
      .filter((l) => l.startsWith('#') || /^(?:\d+\.|[-*])/.test(l))
      .slice(0, 6)
      .map((l, idx) => ({
        id: `sec-${idx + 1}`,
        title: l.replace(/^[#\d.*\s-]+/, '').trim(),
        description: `Notions fondamentales de la partie ${idx + 1}`,
        keyTopics: [l.replace(/^[#\d.*\s-]+/, '').trim()],
        estimatedMinutes: 15,
      }));

    if (fallbackSections.length > 0) {
      return {
        title: defaultTopic,
        targetAudience: 'Étudiants universitaires',
        prerequisites: [],
        sections: fallbackSections,
      };
    }

    throw new InternalError('Failed to parse the generated course outline.');
  }
};

export class GenerateOutlineUseCase {
  constructor(
    private readonly aiGateway: AiGatewayPort,
    private readonly grounding?: CourseKnowledgeGroundingService,
  ) {}

  public async execute(input: GenerateOutlineInput): Promise<GenerateOutlineResult> {
    const topic = (input.topic || input.subject || 'Cours').trim();
    const rawContext = input.sourceContext || input.sourceText;
    const grounded = this.grounding
      ? await this.grounding.resolve({
          requesterId: input.requesterId,
          requesterRole: input.requesterRole,
          query: [topic, (rawContext ?? '').slice(0, 600)].filter(Boolean).join('\n'),
          options: input.knowledge,
          maxChars: OUTLINE_GROUNDING_MAX_CHARS,
        })
      : {
          promptContext: '',
          sources: [],
          searchMode: 'DISABLED' as const,
          degradedReason: null,
        };

    const prompt = buildOutlinePrompt({
      topic,
      level: input.level ?? 'equilibre',
      difficulty: input.difficulty ?? 'moyen',
      sourceContext: rawContext,
      knowledgeContext: grounded.promptContext || undefined,
    });

    const completion = await this.aiGateway.chatCompletion({
      system: prompt.system,
      user: prompt.user,
      maxTokens: 2048,
      temperature: 0.6,
      thinking: false, // fast outline generation
    });

    const outline = parseOutlineJson(completion.content, topic);
    return {
      outline,
      model: completion.model,
      knowledgeSources: grounded.sources,
      knowledgeSearchMode: grounded.searchMode,
      knowledgeDegradedReason: grounded.degradedReason,
    };
  }
}
