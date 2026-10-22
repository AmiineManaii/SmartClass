import { getEnv } from '../../../config/env.js';
import { ConflictError, InternalError, NotFoundError } from '../../../shared/errors/app-error.js';
import type { Role } from '../../auth/index.js';
import type { CourseSectionRepositoryPort } from '../../courses/domain/course-section-repository.port.js';
import type { CourseSection } from '../../courses/domain/course-section.entity.js';
import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import type { AiGatewayPort, GenerateDifficulty, GenerateLevel } from '../domain/ai-gateway.port.js';
import { FETCH_URL_TOOL, WEB_SEARCH_TOOL } from '../domain/ai-tools.js';
import { buildSectionPrompt, COURSE_PROMPT_VERSION } from '../domain/course-prompt.js';
import { loadOwnedCourse } from './course-access.js';
import type { SectionMemoryService } from './section-memory.service.js';

/** Output budget for a single section (a chapter, not the whole course). */
const SECTION_MAX_TOKENS = 8192;

export interface GenerateSectionDTO {
  requesterId: string;
  requesterRole: Role | null;
  courseId: string;
  sectionKey: string;
  /** Regenerating a VALIDATED section demotes it back to GENERATED. */
  regenerate?: boolean;
  level?: GenerateLevel;
  difficulty?: GenerateDifficulty;
  extras?: { examples?: boolean; mermaid?: boolean };
}

/** Alias (not interface) so the SSE controller can spread it into frames. */
export type GenerateSectionMeta = {
  section: CourseSection;
  model: string;
  promptVersion: string;
  /** Sections already written before this one (coherence of the plan). */
  writtenBefore: number;
  /** Validated passages recalled from the teacher's vector memory. */
  memoryHits: number;
  /** True when the section already had content that was overwritten. */
  regenerated: boolean;
  usage: { promptTokens: number | null; completionTokens: number | null };
};

/**
 * Generates the Markdown body of ONE section of a course, streaming the
 * tokens live (SSE). The prompt carries the full plan, the sections
 * already written, and the teacher's own past validated content recalled
 * from pgvector (scoped to the course author — no cross-teacher leakage).
 */
export class GenerateSectionUseCase {
  constructor(
    private readonly gateway: AiGatewayPort,
    private readonly courses: CourseRepositoryPort,
    private readonly sectionRepository: CourseSectionRepositoryPort,
    private readonly memory: SectionMemoryService,
  ) {}

  public async stream(
    dto: GenerateSectionDTO,
    onDelta: (delta: string) => void,
    onPhase: (phase: string) => void = () => undefined,
  ): Promise<GenerateSectionMeta> {
    const course = await loadOwnedCourse(this.courses, dto);
    const sections = await this.sectionRepository.listByCourse(course.id);
    if (sections.length === 0) {
      throw new NotFoundError('Course build not initialized');
    }
    const index = sections.findIndex((section) => section.sectionKey === dto.sectionKey);
    const target = index === -1 ? undefined : sections[index];
    if (index === -1 || !target) {
      throw new NotFoundError('Course section not found');
    }
    if (target.status === 'VALIDATED' && !dto.regenerate) {
      throw new ConflictError(
        'This section is already validated; regenerate it to modify its content',
      );
    }

    onPhase('memory');
    const memory = await this.memory.recall({
      authorId: course.authorId,
      subject: course.subject,
      query: [
        course.title,
        target.title,
        target.description,
        target.keyTopics.join(', '),
      ]
        .filter(Boolean)
        .join('. '),
      k: 3,
    });

    const prompt = buildSectionPrompt({
      courseTitle: course.title,
      targetAudience: course.outline?.targetAudience,
      outlineTitles: sections.map((section) => section.title),
      level: (dto.level ?? (course.level as GenerateLevel)) || 'equilibre',
      difficulty: (dto.difficulty ?? (course.difficulty as GenerateDifficulty)) || 'moyen',
      section: {
        title: target.title,
        description: target.description,
        keyTopics: target.keyTopics,
        estimatedMinutes: target.estimatedMinutes,
      },
      position: { index: index + 1, total: sections.length },
      writtenTitles: sections
        .slice(0, index)
        .filter((section) => section.content?.trim())
        .map((section) => section.title),
      memory,
      extras: {
        examples: dto.extras?.examples ?? true,
        mermaid: dto.extras?.mermaid ?? true,
      },
      toolsOffered: true,
    });

    // Captured BEFORE the save: repository implementations may return the
    // same row object once its content has been overwritten.
    const hadContent = target.content !== null && target.content.trim().length > 0;

    onPhase('generating');
    const env = getEnv();
    let content = '';
    const usage = await this.gateway.streamCompletion(
      {
        system: prompt.system,
        user: prompt.user,
        maxTokens: Math.min(SECTION_MAX_TOKENS, env.AI_MAX_TOKENS),
        temperature: env.AI_TEMPERATURE,
        thinking: true,
        tools: [WEB_SEARCH_TOOL, FETCH_URL_TOOL],
      },
      (delta) => {
        content += delta;
        onDelta(delta);
      },
    );

    const finalContent = content.trim();
    if (finalContent.length === 0) {
      throw new InternalError('The model returned an empty section.');
    }

    const saved = await this.sectionRepository.saveContent({
      courseId: course.id,
      sectionKey: target.sectionKey,
      content: finalContent,
      // A regenerated VALIDATED section must be re-approved (RG4).
      status: 'GENERATED',
    });

    return {
      section: saved,
      model: usage.model,
      promptVersion: COURSE_PROMPT_VERSION,
      writtenBefore: index,
      memoryHits: memory.length,
      regenerated: hadContent,
      usage: {
        promptTokens: usage.promptTokens,
        completionTokens: usage.completionTokens,
      },
    };
  }
}
