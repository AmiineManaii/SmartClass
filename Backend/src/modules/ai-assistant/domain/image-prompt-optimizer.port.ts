import type { ImageKind } from './image-generator.port.js';

export interface ImagePromptOptimizeInput {
  courseTitle: string;
  courseSubject: string | null;
  sectionTitle: string;
  sectionDescription: string;
  keyTopics: string[];
  kind: ImageKind;
}

/** English SDXL prompt pair rewritten by the local LLM. */
export interface OptimizedImagePrompts {
  positive: string;
  negative: string;
}

/**
 * Rewrites section content (possibly French) into an optimized SDXL prompt
 * pair for the `sd_xl_base_1.0` checkpoint: English comma-separated
 * keywords + a visual description, and an English artifact/quality
 * negative. Implemented by the local chat model (Ollama, e.g.
 * Qwen); any failure must throw so the caller falls back to the
 * deterministic template (RG27: everything stays local).
 */
export interface ImagePromptOptimizerPort {
  optimize(input: ImagePromptOptimizeInput): Promise<OptimizedImagePrompts>;
}
