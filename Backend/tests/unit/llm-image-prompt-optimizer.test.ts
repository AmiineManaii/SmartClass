import { describe, expect, it } from 'vitest';
import type { AiGatewayPort } from '../../src/modules/ai-assistant/domain/ai-gateway.port.js';
import type { ImagePromptOptimizeInput } from '../../src/modules/ai-assistant/domain/image-prompt-optimizer.port.js';
import {
  LlmImagePromptOptimizer,
  parseOptimizedPrompts,
} from '../../src/modules/ai-assistant/infrastructure/llm-image-prompt-optimizer.adapter.js';

const INPUT: ImagePromptOptimizeInput = {
  courseTitle: 'Algorithmique avancée',
  courseSubject: 'Informatique',
  sectionTitle: 'Les Artefacts et le Backlog du Produit',
  sectionDescription: 'Analyse détaillée du Product Backlog, priorisation et Sprint Backlog.',
  keyTopics: ['Product Backlog', 'Sprint Backlog', 'priorisation'],
  kind: 'FLOWCHART',
};

const makeGateway = (content: string): AiGatewayPort => ({
  chatCompletion: async () => ({
    content,
    promptTokens: 10,
    completionTokens: 20,
    model: 'hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1',
    toolsUsed: false,
  }),
  streamCompletion: async () => ({ promptTokens: null, completionTokens: null, model: 'x' }),
  checkHealth: async () => ({ available: true, model: 'x', latencyMs: 1 }),
});

const VALID_JSON = JSON.stringify({
  positive:
    'Educational diagram, clean flat vector illustration, labeled nodes, Product Backlog analysis. Visual representation of backlog refinement and Sprint Backlog concept, professional educational design, high quality',
  negative: 'text, watermark, low quality, blurry, extra fingers, cartoon, 3d render, anime',
});

describe('Unit: parseOptimizedPrompts', () => {
  it('parses a bare JSON object', () => {
    expect(parseOptimizedPrompts(VALID_JSON)).toEqual({
      positive: expect.stringContaining('Product Backlog analysis'),
      negative: expect.stringContaining('watermark'),
    });
  });

  it('strips markdown code fences before parsing', () => {
    const fenced = '```json\n' + VALID_JSON + '\n```';
    expect(parseOptimizedPrompts(fenced).positive).toContain('flat vector');
  });

  it('extracts the JSON object from surrounding prose', () => {
    const chatty = 'Here is the prompt pair you asked for:\n' + VALID_JSON + '\nEnjoy!';
    expect(parseOptimizedPrompts(chatty).negative).toContain('blurry');
  });

  it('rejects malformed JSON', () => {
    expect(() => parseOptimizedPrompts('positive: stuff, negative: things')).toThrow(
      /malformed JSON/,
    );
  });

  it('rejects a JSON missing positive or negative', () => {
    expect(() => parseOptimizedPrompts('{"positive": "a valid looking SDXL prompt here ok"}')).toThrow(
      /missing positive\/negative/,
    );
    expect(() =>
      parseOptimizedPrompts('{"positive": "a valid looking SDXL prompt here ok", "negative": ""}'),
    ).toThrow(/missing positive\/negative/);
  });

  it('caps runaway prompts', () => {
    const parsed = parseOptimizedPrompts(
      JSON.stringify({ positive: 'x'.repeat(5000), negative: 'y'.repeat(5000) }),
    );
    expect(parsed.positive.length).toBe(1500);
    expect(parsed.negative.length).toBe(1000);
  });
});

describe('Unit: LlmImagePromptOptimizer', () => {
  it('asks the local model for the SDXL prompt pair and returns it', async () => {
    let sent: { system: string; user: string; thinking?: boolean } | undefined;
    const optimizer = new LlmImagePromptOptimizer({
      ...makeGateway(VALID_JSON),
      chatCompletion: async (input) => {
        sent = input;
        return {
          content: VALID_JSON,
          promptTokens: 10,
          completionTokens: 20,
          model: 'hf.co/unsloth/Qwen3.5-4B-GGUF:Q4_1',
          toolsUsed: false,
        };
      },
    });

    const prompts = await optimizer.optimize(INPUT);

    expect(prompts.positive).toContain('Product Backlog analysis');
    expect(prompts.negative).toContain('watermark');
    expect(sent?.system).toContain('sd_xl_base_1.0.safetensors');
    expect(sent?.system).toContain('ZERO text');
    expect(sent?.system).toContain('two colleagues discussing in front of a blank whiteboard');
    expect(sent?.thinking).toBe(false);
    expect(sent?.user).toContain('Kind: FLOWCHART');
    expect(sent?.user).toContain('Course: Algorithmique avancée (Informatique)');
    expect(sent?.user).toContain('Section: Les Artefacts et le Backlog du Produit');
    expect(sent?.user).toContain('Key points: Product Backlog | Sprint Backlog | priorisation');
  });

  it('propagates gateway failures so the caller can fall back', async () => {
    const optimizer = new LlmImagePromptOptimizer({
      ...makeGateway(VALID_JSON),
      chatCompletion: async () => {
        throw new Error('unsloth down');
      },
    });
    await expect(optimizer.optimize(INPUT)).rejects.toThrow('unsloth down');
  });

  it('propagates malformed model answers as errors', async () => {
    const optimizer = new LlmImagePromptOptimizer(makeGateway('I think the prompts are...'));
    await expect(optimizer.optimize(INPUT)).rejects.toThrow(/JSON/);
  });
});
