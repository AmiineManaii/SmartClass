import { randomInt, randomUUID } from 'node:crypto';
import { getEnv } from '../../../config/env.js';
import { AppError, ImageServiceUnavailableError } from '../../../shared/errors/app-error.js';
import { logger } from '../../../shared/infrastructure/logger.js';
import type {
  ImageGenerateInput,
  ImageGenerateResult,
  ImageGeneratorPort,
} from '../domain/image-generator.port.js';
import workflowJson from './image_sdxl_simple.json' with { type: 'json' };

/**
 * ComfyUI SDXL workflow used for every section illustration
 * (`image_sdxl_simple.json`, API format). The positive prompt, the optional
 * negative prompt, seed and output resolution are rewritten per request;
 * everything else (checkpoint, sampler, steps) comes from the file.
 */
const IMAGE_SIZE = 512;
const QUEUE_TIMEOUT_MS = 15_000;
const POLL_INTERVAL_MS = 1_500;
/**
 * SDXL 30 steps at 512x512 measured at 4-5 min on a GTX 1650: allow 6 min,
 * capped below the client's 7 min receive timeout so the backend stays the
 * one that reports the failure.
 */
const GENERATION_TIMEOUT_MS = 360_000;
const AVAILABILITY_TIMEOUT_MS = 2_000;

/** Appended to the workflow's negative prompt when the caller provides no
 *  optimized negative: SDXL invents unreadable pseudo-text otherwise
 *  (gibberish captions over the illustration). */
const NEGATIVE_SUFFIX =
  ', gibberish, unreadable letters, lorem ipsum, fake text, words, captions, labels, digits';

type WorkflowNode = {
  inputs: Record<string, unknown>;
  class_type: string;
  _meta?: { title?: string };
};
type Workflow = Record<string, WorkflowNode>;
interface ComfyImageRef {
  filename: string;
  subfolder: string;
  type: string;
}
interface QueueResponse {
  prompt_id?: string;
  node_errors?: Record<string, unknown>;
}
interface HistoryEntry {
  status?: { status_str?: string; msg?: string };
  outputs?: Record<string, { images?: ComfyImageRef[] } | undefined>;
}
type History = Record<string, HistoryEntry | undefined>;

const delay = (ms: number): Promise<void> => new Promise((resolve) => setTimeout(resolve, ms));

const buildWorkflowRequest = (input: ImageGenerateInput): Workflow => {
  const workflow = structuredClone(workflowJson) as Workflow;
  const sampler = Object.values(workflow).find((node) => node.class_type === 'KSampler');
  const latent = Object.values(workflow).find((node) => node.class_type === 'EmptyLatentImage');
  if (!sampler || !latent) {
    logger.error({ keys: Object.keys(workflow) }, 'ComfyUI workflow is missing KSampler/EmptyLatentImage');
    throw new ImageServiceUnavailableError();
  }
  const positiveRef = sampler.inputs['positive'];
  const positiveId = Array.isArray(positiveRef) ? positiveRef[0] : undefined;
  const positive = typeof positiveId === 'string' ? workflow[positiveId] : undefined;
  if (positive) {
    positive.inputs['text'] = input.positive;
  } else {
    logger.error({}, 'ComfyUI workflow has no positive prompt node');
    throw new ImageServiceUnavailableError();
  }
  const negativeRef = sampler.inputs['negative'];
  const negativeId = Array.isArray(negativeRef) ? negativeRef[0] : undefined;
  const negative = typeof negativeId === 'string' ? workflow[negativeId] : undefined;
  if (negative && typeof negative.inputs['text'] === 'string') {
    // An optimized negative (from the LLM) replaces the workflow default
    // verbatim; otherwise the default keeps its anti-gibberish suffix.
    negative.inputs['text'] = input.negative?.trim()
      ? input.negative.trim()
      : `${negative.inputs['text']}${NEGATIVE_SUFFIX}`;
  }
  sampler.inputs['seed'] = randomInt(2 ** 31);
  latent.inputs['width'] = IMAGE_SIZE;
  latent.inputs['height'] = IMAGE_SIZE;
  return workflow;
};

const imageToUrl = (base: string, image: ComfyImageRef): string => {
  const query = new URLSearchParams({
    filename: image.filename,
    subfolder: image.subfolder,
    type: image.type,
  });
  return `${base}/view?${query.toString()}`;
};

const waitForImage = async (base: string, promptId: string): Promise<ComfyImageRef> => {
  const deadline = Date.now() + GENERATION_TIMEOUT_MS;
  for (;;) {
    if (Date.now() > deadline) {
      logger.warn({ promptId, elapsedMs: GENERATION_TIMEOUT_MS }, 'ComfyUI generation timed out');
      throw new ImageServiceUnavailableError();
    }
    let entry: HistoryEntry | undefined;
    try {
      const response = await fetch(`${base}/history/${promptId}`, {
        signal: AbortSignal.timeout(QUEUE_TIMEOUT_MS),
      });
      if (response.ok) {
        const history = (await response.json()) as History;
        entry = history[promptId];
      } else {
        logger.warn({ promptId, status: response.status }, 'ComfyUI history lookup failed');
      }
    } catch (error) {
      logger.warn({ promptId, error: (error as Error).message }, 'ComfyUI history request errored');
    }
    if (entry?.status?.status_str === 'error') {
      logger.error({ promptId, msg: entry.status.msg }, 'ComfyUI reported a workflow error');
      throw new ImageServiceUnavailableError();
    }
    const image = Object.values(entry?.outputs ?? {})
      .flatMap((output) => output?.images ?? [])[0];
    if (image) {
      return image;
    }
    await delay(POLL_INTERVAL_MS);
  }
};

/**
 * ComfyUI-backed section illustration generator (RG27: fully local, no
 * third-party image API). The SDXL workflow in `image_sdxl_simple.json`
 * is queued on `COMFYUI_BASE_URL`, polled via `/history` and the produced
 * image is served by ComfyUI's `/view` endpoint. Any misconfiguration or
 * failure (empty base URL, unreachable server, queue error, timeout)
 * answers IMAGE_SERVICE_UNAVAILABLE (503) so the UI can show an honest
 * "coming soon" state instead of a broken image.
 */
export class ComfyUIImageAdapter implements ImageGeneratorPort {
  public async generate(input: ImageGenerateInput): Promise<ImageGenerateResult> {
    const env = getEnv();
    const base = env.COMFYUI_BASE_URL.trim().replace(/\/+$/, '');
    if (!base) {
      logger.debug({ kind: input.kind }, 'ComfyUI not configured; image generation disabled');
      throw new ImageServiceUnavailableError();
    }
    // The app resolves its own host, so the returned URL can use another
    // origin than the one the backend calls (Docker vs client network).
    const publicBase = env.COMFYUI_PUBLIC_URL.trim().replace(/\/+$/, '') || base;
    const workflow = buildWorkflowRequest(input);
    const prompt = input.positive;
    let promptId: string;
    try {
      const response = await fetch(`${base}/prompt`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ prompt: workflow, client_id: randomUUID() }),
        signal: AbortSignal.timeout(QUEUE_TIMEOUT_MS),
      });
      if (!response.ok) {
        logger.warn({ status: response.status }, 'ComfyUI rejected the workflow');
        throw new ImageServiceUnavailableError();
      }
      const queued = (await response.json()) as QueueResponse;
      const nodeErrors = Object.keys(queued.node_errors ?? {});
      if (!queued.prompt_id || nodeErrors.length > 0) {
        logger.error({ promptId: queued.prompt_id, nodeErrors }, 'ComfyUI could not queue the workflow');
        throw new ImageServiceUnavailableError();
      }
      promptId = queued.prompt_id;
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      logger.error({ base, error: (error as Error).message }, 'ComfyUI queue request failed');
      throw new ImageServiceUnavailableError();
    }
    const startedAt = Date.now();
    try {
      const image = await waitForImage(base, promptId);
      const imageUrl = imageToUrl(publicBase, image);
      logger.info(
        { promptId, kind: input.kind, file: image.filename, ms: Date.now() - startedAt },
        'ComfyUI illustration generated',
      );
      return { imageUrl, prompt, provider: 'comfyui' };
    } catch (error) {
      if (error instanceof AppError) {
        throw error;
      }
      logger.error({ promptId, error: (error as Error).message }, 'ComfyUI polling failed');
      throw new ImageServiceUnavailableError();
    }
  }

  public async isAvailable(): Promise<boolean> {
    const base = getEnv().COMFYUI_BASE_URL.trim().replace(/\/+$/, '');
    if (!base) {
      return false;
    }
    try {
      const response = await fetch(`${base}/system_stats`, {
        signal: AbortSignal.timeout(AVAILABILITY_TIMEOUT_MS),
      });
      return response.ok;
    } catch {
      return false;
    }
  }
}
