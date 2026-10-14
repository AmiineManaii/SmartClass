import type { AiGatewayPort } from '../domain/ai-gateway.port.js';
import { buildRefineSectionPrompt } from '../domain/course-prompt.js';
import { InternalError } from '../../../shared/errors/app-error.js';

export interface RefineSectionInput {
  courseTitle?: string;
  selectedText: string;
  instruction: string;
  fullContext?: string;
  courseContent?: string;
}

export class RefineSectionUseCase {
  constructor(private readonly aiGateway: AiGatewayPort) {}

  public async execute(input: RefineSectionInput): Promise<{ refinedText: string; model: string }> {
    if (!input.selectedText || input.selectedText.trim().length === 0) {
      throw new InternalError('No section text selected for refinement.');
    }
    if (!input.instruction || input.instruction.trim().length === 0) {
      throw new InternalError('No modification instruction provided.');
    }

    const prompt = buildRefineSectionPrompt({
      courseTitle: input.courseTitle,
      selectedText: input.selectedText.trim(),
      instruction: input.instruction.trim(),
      fullContext: input.fullContext || input.courseContent,
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
      model: completion.model,
    };
  }
}
