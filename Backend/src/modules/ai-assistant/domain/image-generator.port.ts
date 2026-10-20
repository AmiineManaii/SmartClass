export type ImageKind = 'FIGURE' | 'ARCHITECTURE' | 'FLOWCHART' | 'WORKFLOW';

export interface ImageGenerateInput {
  /** English SDXL positive prompt (LLM-optimized or template fallback). */
  positive: string;
  /** English SDXL negative prompt; the workflow default is used when absent. */
  negative?: string;
  kind: ImageKind;
}

export interface ImageGenerateResult {
  /** Publicly fetchable URL of the generated illustration. */
  imageUrl: string;
  prompt: string;
  provider: string;
}

/**
 * Generates an illustration for a course section (figure, architecture
 * diagram, flowchart, workflow). Implemented by the ComfyUI SDXL adapter
 * (`image_sdxl_simple.json`, 512x512); it receives the already-optimized
 * English prompt pair and reports the service as unavailable when ComfyUI
 * is not configured or unreachable so the UI can show an honest
 * "coming soon" state.
 */
export interface ImageGeneratorPort {
  generate(input: ImageGenerateInput): Promise<ImageGenerateResult>;
  /** Whether the generator is configured and reachable (never throws). */
  isAvailable(): Promise<boolean>;
}
