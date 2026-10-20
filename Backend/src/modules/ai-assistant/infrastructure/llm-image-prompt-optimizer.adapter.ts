import { InternalError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type { AiGatewayPort } from '../domain/ai-gateway.port.js';
import { KIND_STYLE_HINTS } from '../domain/image-prompt.js';
import type {
  ImagePromptOptimizeInput,
  ImagePromptOptimizerPort,
  OptimizedImagePrompts,
} from '../domain/image-prompt-optimizer.port.js';

/**
 * Instructions for rewriting one section into an SDXL prompt pair. The
 * model must answer a bare JSON object — small local models (Qwen) handle
 * this reliably with a low temperature and a short answer budget.
 *
 * HARD RULE: the illustration must contain ZERO text (SDXL cannot render
 * readable words — real labels belong to Mermaid blocks in the course):
 * the positive prompt describes ONE concrete visual scene only, and the
 * negative prompt leads with the whole text family.
 */
const SYSTEM_PROMPT = `You are a prompt engineer for Stable Diffusion XL (checkpoint: sd_xl_base_1.0.safetensors).
Rewrite the educational course section below into an optimized English prompt pair for a text-free illustration.

HARD RULE: the image must contain ZERO text. The positive prompt must describe ONE concrete visual scene — who or what is shown, the action, the setting, and the illustration style — understandable from the scene alone. Only elements a painter could draw: people, objects, arrows and shapes, environment, lighting, colors.
NEVER put these in the positive: text, words, letters, numbers, typography, labels, captions, signage, writing, titles, charts or diagrams with writing, UI screens, slides or whiteboards covered in writing, "labeled nodes", "clear typography".
Example: section "Introduction au Scrum" (keywords: sprint, daily, backlog) → positive: "two colleagues discussing in front of a blank whiteboard in a bright modern workspace, sticky notes and simple arrows on the wall, flat vector illustration, professional educational design, white background, high quality".
Finish the positive with style keywords (flat vector illustration or clean educational style, professional educational design, white background, high quality).
The "negative" prompt MUST start with the whole text family, then quality/artifact terms: "text, words, letters, numbers, typography, captions, labels, writing, watermark, signage, logo, subtitle, low quality, blurry, extra fingers, deformed face, mask error, missing eyes, bad anatomy, overexposure, flat lighting, cartoon, 3d render, anime, comic, plastic, doll, smooth skin".
The kind is only composition guidance (a flowchart becomes arrows connecting shapes or objects between stages — still wordless).
Respond with one JSON object only, no markdown fences, no explanation: {"positive": "...", "negative": "..."}`;

const MAX_TOKENS = 400;
const TEMPERATURE = 0.3;
const POSITIVE_MAX_CHARS = 1500;
const NEGATIVE_MAX_CHARS = 1000;

const buildUserMessage = (input: ImagePromptOptimizeInput): string => {
  const subject = input.courseSubject ? ` (${input.courseSubject})` : '';
  const keyPoints =
    input.keyTopics.length > 0 ? `\nKey points: ${input.keyTopics.join(' | ')}` : '';
  return [
    `Kind: ${input.kind} — style: ${KIND_STYLE_HINTS[input.kind]}`,
    `Course: ${input.courseTitle}${subject}`,
    `Section: ${input.sectionTitle}`,
    `Description: ${input.sectionDescription}`,
    keyPoints,
  ]
    .filter(Boolean)
    .join('\n');
};

/** Strips code fences and extracts the first {...} block. */
const extractJsonObject = (content: string): string => {
  const cleaned = content.replace(/```(?:json)?/gi, '');
  const match = cleaned.match(/\{[\s\S]*\}/);
  if (!match) {
    throw new InternalError('SDXL prompt optimizer returned no JSON object.');
  }
  return match[0];
};

export const parseOptimizedPrompts = (content: string): OptimizedImagePrompts => {
  let parsed: unknown;
  try {
    parsed = JSON.parse(extractJsonObject(content));
  } catch {
    throw new InternalError('SDXL prompt optimizer returned malformed JSON.');
  }
  if (typeof parsed !== 'object' || parsed === null) {
    throw new InternalError('SDXL prompt optimizer returned a non-object JSON.');
  }
  const { positive, negative } = parsed as Record<string, unknown>;
  if (
    typeof positive !== 'string' ||
    typeof negative !== 'string' ||
    positive.trim().length < 20 ||
    negative.trim().length < 5
  ) {
    throw new InternalError('SDXL prompt optimizer JSON is missing positive/negative.');
  }
  return {
    positive: positive.trim().slice(0, POSITIVE_MAX_CHARS),
    negative: negative.trim().slice(0, NEGATIVE_MAX_CHARS),
  };
};

/**
 * Optimizes SDXL prompts through the local chat model (Unsloth/Ollama —
 * the same gateway as course generation, with its primary/fallback model
 * chain). Used by `GenerateSectionImageUseCase`, which falls back to the
 * deterministic template on any error thrown here.
 */
export class LlmImagePromptOptimizer implements ImagePromptOptimizerPort {
  constructor(private readonly gateway: AiGatewayPort) {}

  public async optimize(input: ImagePromptOptimizeInput): Promise<OptimizedImagePrompts> {
    const result = await this.gateway.chatCompletion({
      system: SYSTEM_PROMPT,
      user: buildUserMessage(input),
      maxTokens: MAX_TOKENS,
      temperature: TEMPERATURE,
      thinking: false,
    });
    const prompts = parseOptimizedPrompts(result.content);
    logger.info(
      { kind: input.kind, model: result.model, positiveChars: prompts.positive.length },
      'SDXL prompts optimized by the local LLM',
    );
    return prompts;
  }
}
