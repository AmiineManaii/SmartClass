import { afterEach, describe, expect, it, vi } from 'vitest';

const ORIGINAL_BASE = process.env.COMFYUI_BASE_URL;
const ORIGINAL_PUBLIC = process.env.COMFYUI_PUBLIC_URL;

interface CapturedCall {
  url: string;
  init?: RequestInit;
}

const loadAdapter = async () => {
  vi.resetModules();
  return import('../../src/modules/ai-assistant/infrastructure/comfyui-image.adapter');
};

const stubFetch = (handler: (call: CapturedCall) => Response | Promise<Response>) => {
  const calls: CapturedCall[] = [];
  const mock = vi.fn(async (url: string | URL | Request, init?: RequestInit) =>
    handler({ url: String(url), init }),
  );
  vi.stubGlobal('fetch', mock);
  return { calls, mock };
};

const okJson = (body: unknown): Response =>
  new Response(JSON.stringify(body), { status: 200, headers: { 'Content-Type': 'application/json' } });

const generateInput = {
  positive: 'educational diagram, queue management, process flow',
  negative: 'text, watermark, low quality, blurry',
  kind: 'FLOWCHART' as const,
};

const loadGenerate = async () => {
  const { ComfyUIImageAdapter } = await loadAdapter();
  const adapter = new ComfyUIImageAdapter();
  return (input = generateInput) => adapter.generate(input);
};

describe('Unit: ComfyUIImageAdapter (SDXL workflow)', () => {
  afterEach(() => {
    vi.unstubAllGlobals();
    if (ORIGINAL_BASE === undefined) {
      delete process.env.COMFYUI_BASE_URL;
    } else {
      process.env.COMFYUI_BASE_URL = ORIGINAL_BASE;
    }
    if (ORIGINAL_PUBLIC === undefined) {
      delete process.env.COMFYUI_PUBLIC_URL;
    } else {
      process.env.COMFYUI_PUBLIC_URL = ORIGINAL_PUBLIC;
    }
  });

  it('answers 503 IMAGE_SERVICE_UNAVAILABLE when COMFYUI_BASE_URL is empty', async () => {
    process.env.COMFYUI_BASE_URL = '';
    const generate = await loadGenerate();
    await expect(generate(generateInput)).rejects.toMatchObject({
      code: 'IMAGE_SERVICE_UNAVAILABLE',
    });
  });

  it('queues the workflow with a 512x512 latent, the section prompt and a fresh seed', async () => {
    process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188/';
    let queuedBody: Record<string, unknown> | undefined;
    stubFetch((call) => {
      if (call.url.endsWith('/prompt')) {
        queuedBody = JSON.parse(String(call.init?.body)) as Record<string, unknown>;
        return okJson({ prompt_id: 'p-1', node_errors: {} });
      }
      return okJson({
        'p-1': {
          status: { status_str: 'success' },
          outputs: {
            '7': {
              images: [{ filename: 'sdxl_simple_00001_.png', subfolder: '', type: 'output' }],
            },
          },
        },
      });
    });
    const generate = await loadGenerate();

    const result = await generate(generateInput);

    expect(result.provider).toBe('comfyui');
    expect(result.prompt).toBe(generateInput.positive);
    expect(result.imageUrl).toBe(
      'http://comfy.test:8188/view?filename=sdxl_simple_00001_.png&subfolder=&type=output',
    );
    expect(queuedBody).toBeDefined();
    const workflow = queuedBody?.['prompt'] as Record<
      string,
      { class_type: string; inputs: Record<string, unknown> }
    >;
    expect(typeof queuedBody?.['client_id']).toBe('string');
    const latent = Object.values(workflow).find((n) => n.class_type === 'EmptyLatentImage');
    expect(latent?.inputs).toMatchObject({ width: 512, height: 512, batch_size: 1 });
    const sampler = Object.values(workflow).find((n) => n.class_type === 'KSampler');
    expect(sampler).toBeDefined();
    expect(sampler?.inputs['seed']).not.toBe(209087739553733);
    expect(typeof sampler?.inputs['seed']).toBe('number');
    const positiveRef = sampler?.inputs['positive'] as [string, number];
    expect(workflow[positiveRef[0] ?? '']?.inputs['text']).toBe(result.prompt);
    const negativeRef = sampler?.inputs['negative'] as [string, number];
    const negativeText = String(workflow[negativeRef[0] ?? '']?.inputs['text']);
    expect(negativeText).toBe(generateInput.negative);
    expect(negativeText).not.toContain('gibberish');
  });

  it('keeps the workflow default negative (plus gibberish suffix) when no negative is provided', async () => {
    process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188';
    let queuedBody: Record<string, unknown> | undefined;
    stubFetch((call) => {
      if (call.url.endsWith('/prompt')) {
        queuedBody = JSON.parse(String(call.init?.body)) as Record<string, unknown>;
        return okJson({ prompt_id: 'p-1', node_errors: {} });
      }
      return okJson({
        'p-1': {
          status: { status_str: 'success' },
          outputs: {
            '7': {
              images: [{ filename: 'sdxl_simple_00001_.png', subfolder: '', type: 'output' }],
            },
          },
        },
      });
    });
    const generate = await loadGenerate();

    await generate({ positive: 'clean educational diagram, tri rapide', kind: 'FIGURE' });

    const workflow = queuedBody?.['prompt'] as Record<
      string,
      { class_type: string; inputs: Record<string, unknown> }
    >;
    const sampler = Object.values(workflow).find((n) => n.class_type === 'KSampler');
    const negativeRef = sampler?.inputs['negative'] as [string, number];
    const negativeText = String(workflow[negativeRef[0] ?? '']?.inputs['text']);
    expect(negativeText).toContain('watermark');
    expect(negativeText).toContain('gibberish');
  });

  it('queues on COMFYUI_BASE_URL but returns imageUrl on COMFYUI_PUBLIC_URL', async () => {
    process.env.COMFYUI_BASE_URL = 'http://host.docker.internal:8188';
    process.env.COMFYUI_PUBLIC_URL = 'http://localhost:8188';
    const queuedUrls: string[] = [];
    stubFetch((call) => {
      queuedUrls.push(call.url);
      if (call.url.endsWith('/prompt')) {
        return okJson({ prompt_id: 'p-9', node_errors: {} });
      }
      return okJson({
        'p-9': {
          status: { status_str: 'success' },
          outputs: { '7': { images: [{ filename: 'a.png', subfolder: '', type: 'output' }] } },
        },
      });
    });
    const generate = await loadGenerate();

    const result = await generate(generateInput);

    expect(result.imageUrl).toBe('http://localhost:8188/view?filename=a.png&subfolder=&type=output');
    expect(queuedUrls.every((url) => url.startsWith('http://host.docker.internal:8188/'))).toBe(true);
  });

  it('polls history until the image appears', async () => {
    process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188';
    let historyCalls = 0;
    stubFetch((call) => {
      if (call.url.endsWith('/prompt')) {
        return okJson({ prompt_id: 'p-2', node_errors: {} });
      }
      historyCalls += 1;
      if (historyCalls === 1) {
        return okJson({ 'p-2': { status: { status_str: 'running' }, outputs: {} } });
      }
      return okJson({
        'p-2': {
          status: { status_str: 'success' },
          outputs: {
            '7': { images: [{ filename: 'out.png', subfolder: 'sub', type: 'output' }] },
          },
        },
      });
    });
    const generate = await loadGenerate();

    const result = await generate(generateInput);

    expect(historyCalls).toBe(2);
    expect(result.imageUrl).toBe('http://comfy.test:8188/view?filename=out.png&subfolder=sub&type=output');
  });

  it('answers 503 when ComfyUI rejects the workflow', async () => {
    process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188';
    stubFetch(() => new Response('bad request', { status: 400 }));
    const generate = await loadGenerate();
    await expect(generate(generateInput)).rejects.toMatchObject({
      code: 'IMAGE_SERVICE_UNAVAILABLE',
    });
  });

  it('answers 503 when the queue reports node errors', async () => {
    process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188';
    stubFetch(() => okJson({ prompt_id: undefined, node_errors: { '15': { errors: ['missing ckpt'] } } }));
    const generate = await loadGenerate();
    await expect(generate(generateInput)).rejects.toMatchObject({
      code: 'IMAGE_SERVICE_UNAVAILABLE',
    });
  });

  it('answers 503 when the workflow errors in history', async () => {
    process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188';
    stubFetch((call) =>
      call.url.endsWith('/prompt')
        ? okJson({ prompt_id: 'p-3', node_errors: {} })
        : okJson({ 'p-3': { status: { status_str: 'error', msg: 'Value not in list' }, outputs: {} } }),
    );
    const generate = await loadGenerate();
    await expect(generate(generateInput)).rejects.toMatchObject({
      code: 'IMAGE_SERVICE_UNAVAILABLE',
    });
  });

  it('answers 503 when ComfyUI is unreachable', async () => {
    process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188';
    stubFetch(() => {
      throw new TypeError('fetch failed');
    });
    const generate = await loadGenerate();
    await expect(generate(generateInput)).rejects.toMatchObject({
      code: 'IMAGE_SERVICE_UNAVAILABLE',
    });
  });

  describe('isAvailable', () => {
    it('is false when not configured', async () => {
      process.env.COMFYUI_BASE_URL = '';
      const { ComfyUIImageAdapter } = await loadAdapter();
      await expect(new ComfyUIImageAdapter().isAvailable()).resolves.toBe(false);
    });

    it('is true when ComfyUI answers system_stats', async () => {
      process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188';
      stubFetch(() => okJson({ system: {} }));
      const { ComfyUIImageAdapter } = await loadAdapter();
      await expect(new ComfyUIImageAdapter().isAvailable()).resolves.toBe(true);
    });

    it('is false when the ping fails', async () => {
      process.env.COMFYUI_BASE_URL = 'http://comfy.test:8188';
      stubFetch(() => {
        throw new TypeError('fetch failed');
      });
      const { ComfyUIImageAdapter } = await loadAdapter();
      await expect(new ComfyUIImageAdapter().isAvailable()).resolves.toBe(false);
    });
  });
});
