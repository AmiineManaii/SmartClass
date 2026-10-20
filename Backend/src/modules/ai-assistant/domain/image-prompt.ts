import type { ImageKind } from './image-generator.port.js';

/** Style keywords per illustration kind (template fallback only) — all
 *  wordless: the image must never contain text. */
export const KIND_PROMPTS: Record<ImageKind, string> = {
  FIGURE: 'clean educational illustration, flat vector style, schematic icons, simple shapes',
  ARCHITECTURE: 'connected blocks and arrows, schematic system illustration',
  FLOWCHART: 'shapes connected by directional arrows, wordless flowchart composition',
  WORKFLOW: 'stages connected by arrows, wordless step-by-step composition',
};

/** Wordless composition hints fed to the LLM prompt optimizer (the image
 *  must contain zero text: shapes, objects and arrows only). */
export const KIND_STYLE_HINTS: Record<ImageKind, string> = {
  FIGURE: 'educational illustration, flat vector style, clear visual metaphor',
  ARCHITECTURE: 'connected blocks and arrows between systems, wordless',
  FLOWCHART: 'shapes connected by arrows showing the process, wordless',
  WORKFLOW: 'stages connected by arrows, objects or people moving through steps, wordless',
};

/** SDXL cannot render readable text: the illustration must stay text-free
 *  (real labels belong to Mermaid blocks in the course content). */
const TEXT_FREE =
  ' Text-free composition: no text, no words, no letters, no numbers, no captions anywhere.';

/**
 * Deterministic English template used when the LLM prompt optimizer is
 * unavailable (Unsloth down, malformed JSON…): quality prefix + kind style
 * + the section topic in its original language.
 */
export const buildImagePrompt = (input: {
  title: string;
  description: string;
  kind: ImageKind;
}): string =>
  `masterpiece, best quality, ${KIND_PROMPTS[input.kind]} depicting exactly the topic: "${input.title}". ${input.description}${TEXT_FREE}`.trim();
