import { describe, it, expect, afterEach } from 'vitest';
import { createServer, type Server } from 'node:http';
import { OpenAICompatibleGateway } from '../../src/modules/ai-assistant/infrastructure/openai-compatible-gateway.adapter.js';

const input = {
  system: 'sys',
  user: 'hello',
  maxTokens: 16384,
  temperature: 0.7,
};

let server: Server | null = null;

afterEach(async () => {
  if (server) {
    await new Promise<void>((resolve) => server?.close(() => resolve()));
    server = null;
  }
});

const stub = async (
  handler: (body: Record<string, unknown>) => { status: number; payload: unknown },
): Promise<string> => {
  let seen: Record<string, unknown> = {};
  server = createServer((req, res) => {
    let raw = '';
    req.on('data', (chunk: Buffer) => {
      raw += chunk.toString();
    });
    req.on('end', () => {
      try {
        seen = JSON.parse(raw || '{}') as Record<string, unknown>;
      } catch {
        seen = {};
      }
      const { status, payload } = handler(seen);
      res.writeHead(status, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(payload));
    });
  });
  await new Promise<void>((resolve) => server?.listen(0, '127.0.0.1', resolve));
  const address = server?.address();
  const port = typeof address === 'object' && address ? address.port : 0;
  return `http://127.0.0.1:${port}`;
};

describe('Unit: OpenAICompatibleGateway', () => {
  it('returns content and usage on success', async () => {    const baseUrl = await stub(() => ({
      status: 200,
      payload: {
        model: 'qwen-test',
        choices: [{ message: { content: '# Cours' } }],
        usage: { prompt_tokens: 5, completion_tokens: 7 },
      },
    }));
    const gateway = new OpenAICompatibleGateway({ baseUrl, model: 'qwen-test' });
    const result = await gateway.chatCompletion(input);
    expect(result.content).toBe('# Cours');
    expect(result.promptTokens).toBe(5);
    expect(result.completionTokens).toBe(7);
    expect(result.toolsUsed).toBe(false);
  });

  it('retries without tools when the server rejects them (400)', async () => {
    let calls = 0;
    const baseUrl = await stub((body) => {
      calls += 1;
      if (calls === 1) {
        if (!('tools' in body)) throw new Error('expected tools on first call');
        return { status: 400, payload: { error: { message: 'no tools' } } };
      }
      if ('tools' in body) throw new Error('tools must be dropped on retry');
      return {
        status: 200,
        payload: { choices: [{ message: { content: 'ok' } }] },
      };
    });
    const gateway = new OpenAICompatibleGateway({ baseUrl });
    const result = await gateway.chatCompletion({
      ...input,
      tools: [
        {
          type: 'function',
          function: { name: 'web_search', description: 'd', parameters: {} },
        },
      ],
    });
    expect(result.content).toBe('ok');
    expect(result.toolsUsed).toBe(false);
    expect(calls).toBe(2);
  });

  it('throws 503 when the gateway is unreachable', async () => {
    const gateway = new OpenAICompatibleGateway({
      baseUrl: 'http://127.0.0.1:1',
      timeoutMs: 1000,
      statusTimeoutMs: 1000,
    });
    await expect(gateway.chatCompletion(input)).rejects.toMatchObject({
      statusCode: 503,
      code: 'SERVICE_UNAVAILABLE',
    });
    await expect(gateway.checkHealth()).resolves.toMatchObject({ available: false });
  });

  it('throws 500 on empty completions', async () => {
    const baseUrl = await stub(() => ({
      status: 200,
      payload: { choices: [{ message: { content: '   ' } }] },
    }));
    const gateway = new OpenAICompatibleGateway({ baseUrl });
    await expect(gateway.chatCompletion(input)).rejects.toMatchObject({ statusCode: 500 });
  });

  it('sends the API key on chat and health calls (Unsloth requires auth)', async () => {    const seenHeaders: Array<Record<string, string | string[] | undefined>> = [];
    const { createServer: create } = await import('node:http');
    const keyed = create((req, res) => {
      seenHeaders.push({ ...req.headers });
      req.resume();
      req.on('end', () => {
        if (req.url === '/v1/models') {
          res.writeHead(200, { 'Content-Type': 'application/json' });
          res.end(JSON.stringify({ object: 'list', data: [] }));
          return;
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ choices: [{ message: { content: 'ok' } }] }));
      });
    });
    await new Promise<void>((resolve) => keyed.listen(0, '127.0.0.1', resolve));
    const address = keyed.address();
    const port = typeof address === 'object' && address ? address.port : 0;
    try {
      const gateway = new OpenAICompatibleGateway({
        baseUrl: `http://127.0.0.1:${port}`,
        apiKey: 'sk-test-key',
      });
      await gateway.chatCompletion(input);
      await gateway.checkHealth();
    } finally {
      await new Promise<void>((resolve) => keyed.close(() => resolve()));
    }
    // Both calls must carry the API key (Unsloth requires auth, even on
    // GET /v1/models).
    expect(seenHeaders).toHaveLength(2);
    for (const headers of seenHeaders) {
      expect(headers.authorization).toBe('Bearer sk-test-key');
    }
  });

  it('sends the full Unsloth toolset and execution flags', async () => {
    let seen: Record<string, unknown> = {};
    const { createServer: create } = await import('node:http');
    const sse = create((req, res) => {
      let raw = '';
      req.on('data', (chunk: Buffer) => {
        raw += chunk.toString();
      });
      req.on('end', () => {
        try {
          seen = JSON.parse(raw || '{}') as Record<string, unknown>;
        } catch {
          seen = {};
        }
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ choices: [{ message: { content: 'ok' } }] }));
      });
    });
    await new Promise<void>((resolve) => sse.listen(0, '127.0.0.1', resolve));
    const address = sse.address();
    const port = typeof address === 'object' && address ? address.port : 0;
    try {
      const gateway = new OpenAICompatibleGateway({
        baseUrl: `http://127.0.0.1:${port}`,
      });
      const { WEB_SEARCH_TOOL, FETCH_URL_TOOL, EXECUTE_CODE_TOOL, CALCULATOR_TOOL } =
        await import('../../src/modules/ai-assistant/domain/ai-tools.js');
      await gateway.chatCompletion({
        ...input,
        tools: [WEB_SEARCH_TOOL, FETCH_URL_TOOL, EXECUTE_CODE_TOOL, CALCULATOR_TOOL],
      });
    } finally {
      await new Promise<void>((resolve) => sse.close(() => resolve()));
    }
    const tools = seen.tools as Array<{ function: { name: string } }>;
    expect(tools.map((tool) => tool.function.name).sort()).toEqual([
      'calculator',
      'execute_code',
      'fetch_url',
      'web_search',
    ]);
    expect(seen.tool_choice).toBe('auto');
    expect(seen.chat_template_kwargs).toMatchObject({ enable_thinking: true });
    expect(seen.enable_tools).toBe(true);
    expect(seen.tool_servers).toEqual(
      expect.arrayContaining(['web_search', 'fetch_url', 'execute_code', 'calculator']),
    );
    expect(seen.auto_execute_tools).toBe(true);
    expect(typeof seen.max_tool_iterations).toBe('number');
    expect(seen.permission_mode).toBe('off');
  });

  it('sends the thinking flag even without tools (cheap courses skip thinking)', async () => {
    let seen: Record<string, unknown> = {};
    const baseUrl = await stub((body) => {
      seen = body;
      return {
        status: 200,
        payload: { choices: [{ message: { content: 'ok' } }] },
      };
    });
    const gateway = new OpenAICompatibleGateway({ baseUrl });
    await gateway.chatCompletion({ ...input, thinking: false });
    expect(seen.chat_template_kwargs).toMatchObject({ enable_thinking: false });
    expect(seen).not.toHaveProperty('tools');
  });

  it('streams deltas live and resolves usage at [DONE]', async () => {
    const { createServer: create } = await import('node:http');
    const frames = [
      'data: {"choices":[{"delta":{"content":"# Cou"}}]}',
      'data: {"choices":[{"delta":{"content":"rs"}}]}',
      'data: {"usage":{"prompt_tokens":7,"completion_tokens":9},"model":"qwen-test"}',
      'data: [DONE]',
    ];
    const sse = create((req, res) => {
      res.writeHead(200, { 'Content-Type': 'text/event-stream' });
      res.end(`${frames.join('\n\n')}\n\n`);
    });
    await new Promise<void>((resolve) => sse.listen(0, '127.0.0.1', resolve));
    const address = sse.address();
    const port = typeof address === 'object' && address ? address.port : 0;
    try {
      const gateway = new OpenAICompatibleGateway({
        baseUrl: `http://127.0.0.1:${port}`,
      });
      const deltas: string[] = [];
      const usage = await gateway.streamCompletion(input, (delta) =>
        deltas.push(delta),
      );
      expect(deltas.join('')).toBe('# Cours');
      expect(usage).toMatchObject({
        promptTokens: 7,
        completionTokens: 9,
        model: 'qwen-test',
      });
    } finally {
      await new Promise<void>((resolve) => sse.close(() => resolve()));
    }
  });
});
