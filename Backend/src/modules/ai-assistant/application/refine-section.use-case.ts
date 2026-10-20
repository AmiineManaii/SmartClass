import type { CourseRepositoryPort } from '../../courses/domain/course-repository.port.js';
import type { AiGatewayPort } from '../domain/ai-gateway.port.js';
import { buildRefineSectionPrompt } from '../domain/course-prompt.js';
import { InternalError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import { loadOwnedCourse } from './course-access.js';
import type { SectionMemoryService } from './section-memory.service.js';

export interface RefineSectionInput {
  courseTitle?: string;
  /** Optional: scopes the vector recall to this course's subject. */
  courseId?: string;
  selectedText: string;
  instruction: string;
  fullContext?: string;
  courseContent?: string;
  /** Caller identity for memory scoping (controller injects req.user). */
  requesterId?: string;
  requesterRole?: 'TEACHER' | 'ADMIN' | 'STUDENT' | null;
}

export interface RefineSectionResult {
  /** Replacement text (historical key kept for existing clients). */
  refinedText: string;
  /** Same content under the key the mobile app actually reads. */
  revisedText: string;
  /** One-sentence summary of the change (null when unavailable). */
  explanation: string | null;
  model: string;
}

/**
 * Applies one teacher instruction to a selected passage.
 *
 * Recalls the teacher's own validated passages from vector memory so the
 * revision keeps their terminology, and returns the replacement text under
 * BOTH `refinedText` and `revisedText` (contract drift fix: the backend
 * used to send only `refinedText` while the client reads `revisedText`).
 */
export class RefineSectionUseCase {
  constructor(
    private readonly aiGateway: AiGatewayPort,
    private readonly courses?: CourseRepositoryPort,
    private readonly memory?: SectionMemoryService,
  ) {}

  public async execute(input: RefineSectionInput): Promise<RefineSectionResult> {
    if (!input.selectedText || input.selectedText.trim().length === 0) {
      throw new InternalError('No section text selected for refinement.');
    }
    if (!input.instruction || input.instruction.trim().length === 0) {
      throw new InternalError('No modification instruction provided.');
    }

    const memory = await this.recallMemory(input);

    const prompt = buildRefineSectionPrompt({
      courseTitle: input.courseTitle,
      selectedText: input.selectedText.trim(),
      instruction: input.instruction.trim(),
      fullContext: input.fullContext || input.courseContent,
      memory,
    });

    const completion = await this.aiGateway.chatCompletion({
      system: prompt.system,
      user: prompt.user,
      maxTokens: 4096,
      temperature: 0.6,
      thinking: false, // fast targeted refinement
    });

    const refinedText = completion.content.trim();
    return {
      refinedText,
      revisedText: refinedText,
      explanation: await this.explainChange(input, refinedText),
      model: completion.model,
    };
  }

  /** Vector recall scoped to the course author (best-effort, never throws). */
  private async recallMemory(input: RefineSectionInput): Promise<
    { title: string; content: string }[]
  > {
    if (!this.memory || !input.requesterId) return [];
    let authorId = input.requesterId;
    let subject: string | null = null;
    if (input.courseId && this.courses) {
      const course = await loadOwnedCourse(this.courses, {
        requesterId: input.requesterId,
        requesterRole: input.requesterRole ?? null,
        courseId: input.courseId,
      });
      authorId = course.authorId;
      subject = course.subject;
    }
    return this.memory.recall({
      authorId,
      subject,
      query: [
        input.courseTitle ?? '',
        input.instruction,
        input.selectedText.slice(0, 400),
      ]
        .filter(Boolean)
        .join('. '),
      k: 2,
    });
  }

  /** One-sentence explanation of the revision (best-effort, never throws). */
  private async explainChange(
    input: RefineSectionInput,
    refinedText: string,
  ): Promise<string | null> {
    try {
      const completion = await this.aiGateway.chatCompletion({
        system:
          `Tu résumes une modification de cours.\n` +
          `Réponds par UNE SEULE phrase en français expliquant en quoi le nouveau texte ` +
          `diffère du passage original suite à la consigne. Pas de préambule, pas de Markdown.`,
        user:
          `Passage original :\n${input.selectedText.slice(0, 1200)}\n\n` +
          `Consigne de l'enseignant : ${input.instruction}\n\n` +
          `Nouveau texte :\n${refinedText.slice(0, 1200)}`,
        maxTokens: 200,
        temperature: 0.2,
        thinking: false,
      });
      const explanation = completion.content.trim();
      return explanation.length > 0 ? explanation : null;
    } catch (error) {
      logger.debug({ err: error }, 'Refinement explanation unavailable');
      return null;
    }
  }
}
